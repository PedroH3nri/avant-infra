#!/usr/bin/env bash
# Firewall de saída dos containers do Avant numa VM (staging ou produção). Rode como root.
#
#   scripts/firewall-saida.sh <ambiente>           aplica as regras (pode rodar de novo)
#   scripts/firewall-saida.sh <ambiente> status    mostra as regras em uso
#
# Os containers da rede avant-<ambiente> não abrem conexão nova para redes privadas (RFC 1918),
# CGNAT, link-local e metadados da nuvem (169.254.169.254), nem para o próprio host: é a defesa
# contra SSRF do worker e da api. Continuam liberados a própria rede do Docker (Postgres, Redis,
# RabbitMQ e nginx do stack), o DNS da VM e os destinos de AVANT_EGRESS_ALLOW ("ip:porta",
# separados por espaço; por exemplo o MongoDB do iGroone/data num endereço privado).
# As regras são só IPv4: o script recusa a rede do Docker com IPv6 ligado (NAT64, worker#161).
set -euo pipefail

BLOCKED_NETWORKS=(
  0.0.0.0/8
  10.0.0.0/8
  100.64.0.0/10
  169.254.0.0/16
  172.16.0.0/12
  192.168.0.0/16
  198.18.0.0/15
  224.0.0.0/4
  240.0.0.0/4
)
SYSTEMD_RESOLV_CONF=/run/systemd/resolve/resolv.conf

# Mostra o erro e encerra.
die() { echo "firewall-saida: $*" >&2; exit 1; }
# Mostra uma linha de progresso.
log() { echo "firewall-saida: $*"; }

# Devolve o nome da interface bridge da rede do Docker do ambiente (br- e 12 letras do id).
bridge_of() {
  local network="$1" network_id ipv6_enabled
  network_id="$(docker network inspect -f '{{.Id}}' "$network" 2>/dev/null)" \
    || die "a rede $network não existe: rode scripts/deploy.sh <ambiente> up antes"
  ipv6_enabled="$(docker network inspect -f '{{.EnableIPv6}}' "$network")"
  [[ "$ipv6_enabled" == false ]] || die "a rede $network tem IPv6 ligado; as regras daqui são só IPv4"
  echo "br-${network_id:0:12}"
}

# Lista os servidores DNS que o Docker repassa aos containers (fora os de loopback).
dns_servers() {
  local resolv_conf=/etc/resolv.conf
  [[ -f "$SYSTEMD_RESOLV_CONF" ]] && resolv_conf="$SYSTEMD_RESOLV_CONF"
  awk '$1 == "nameserver" && $2 ~ /^[0-9.]+$/ && $2 !~ /^127\./ { print $2 }' "$resolv_conf"
}

# Cria a chain vazia (ou esvazia a que já existe).
reset_chain() {
  local chain="$1"
  iptables -N "$chain" 2>/dev/null || iptables -F "$chain"
}

# Tira todos os saltos de uma chain do sistema para a nossa (ficam de bridges antigas).
remove_jumps() {
  local parent_chain="$1" chain="$2" current_rules rule
  local -a rule_words
  current_rules="$(iptables -S "$parent_chain")"
  while read -r rule; do
    [[ "$rule" == *"-j $chain" ]] || continue
    read -r -a rule_words <<< "${rule/-A /-D }"
    iptables "${rule_words[@]}"
  done <<< "$current_rules"
}

# Põe as exceções (DNS e AVANT_EGRESS_ALLOW) e depois os bloqueios na chain.
fill_chain() {
  local chain="$1" allowed address port dns_server
  iptables -A "$chain" -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
  for dns_server in $(dns_servers); do
    iptables -A "$chain" -d "$dns_server" -p udp --dport 53 -j RETURN
    iptables -A "$chain" -d "$dns_server" -p tcp --dport 53 -j RETURN
  done
  for allowed in ${AVANT_EGRESS_ALLOW:-}; do
    address="${allowed%:*}"
    port="${allowed##*:}"
    iptables -A "$chain" -d "$address" -p tcp --dport "$port" -j RETURN
  done
}

# Recusa AVANT_EGRESS_ALLOW fora do formato ip:porta antes de mexer em qualquer regra.
validate_allow_list() {
  local allowed
  for allowed in ${AVANT_EGRESS_ALLOW:-}; do
    [[ "$allowed" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?:[0-9]{1,5}$ ]] \
      || die "AVANT_EGRESS_ALLOW inválido: $allowed (use ip:porta)"
  done
}

# Aplica as duas chains: saída para outras redes (DOCKER-USER) e para o próprio host (INPUT).
apply() {
  local bridge="$1" forward_chain="$2" input_chain="$3" blocked_network
  reset_chain "$forward_chain"
  fill_chain "$forward_chain"
  iptables -A "$forward_chain" -o "$bridge" -j RETURN
  for blocked_network in "${BLOCKED_NETWORKS[@]}"; do
    iptables -A "$forward_chain" -d "$blocked_network" -j DROP
  done
  remove_jumps DOCKER-USER "$forward_chain"
  iptables -I DOCKER-USER -i "$bridge" -j "$forward_chain"

  reset_chain "$input_chain"
  fill_chain "$input_chain"
  iptables -A "$input_chain" -j DROP
  remove_jumps INPUT "$input_chain"
  iptables -I INPUT -i "$bridge" -j "$input_chain"
  log "regras aplicadas na bridge $bridge ($forward_chain e $input_chain)"
}

[[ $# -ge 1 ]] || die "uso: $0 <staging|production> [status]"
ENV_NAME="$1"
ACTION="${2:-apply}"
case "$ENV_NAME" in staging|production) ;; *) die "ambiente desconhecido: $ENV_NAME" ;; esac
[[ "$(id -u)" == 0 ]] || die "rode como root"
FORWARD_CHAIN="AVANT-SAIDA-$ENV_NAME"
INPUT_CHAIN="AVANT-HOST-$ENV_NAME"

case "$ACTION" in
  apply)
    validate_allow_list
    BRIDGE="$(bridge_of "avant-$ENV_NAME")"
    apply "$BRIDGE" "$FORWARD_CHAIN" "$INPUT_CHAIN"
    ;;
  status)
    iptables -S DOCKER-USER
    iptables -S "$FORWARD_CHAIN"
    iptables -S "$INPUT_CHAIN"
    ;;
  *) die "ação desconhecida: $ACTION" ;;
esac
