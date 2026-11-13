#!/usr/bin/env bash
# Firewall de saída dos containers do Avant numa VM (staging ou produção). Rode como root.
#
#   scripts/firewall-saida.sh <ambiente>           aplica as regras (pode rodar de novo)
#   scripts/firewall-saida.sh <ambiente> status    mostra as regras em uso
#
# Os containers da rede avant-<ambiente> (bridge com nome fixo, AVANT_BRIDGE do vm.env) não abrem
# conexão nova para redes privadas (RFC 1918), CGNAT, link-local e metadados da nuvem
# (169.254.169.254), nem para o próprio host: é a defesa contra SSRF do worker e da api.
# Continuam liberados a própria rede do Docker (Postgres, Redis, RabbitMQ e nginx do stack), o
# DNS da VM e os destinos de AVANT_EGRESS_ALLOW ("ip:porta" ou "ip/prefixo:porta", prefixo de
# 24 a 32, separados por espaço; por exemplo o MongoDB do iGroone/data). O destino liberado é o
# original da conexão, antes do DNAT: vale o IP:porta publicado, não o IP do container.
#
# As regras entram de uma vez, numa transação do iptables-restore: se qualquer linha falhar,
# nada muda e as regras anteriores (com os DROPs) continuam. Depois de aplicar, grava a bridge
# em /run/avant-firewall/<ambiente>, que o deploy.sh confere.
# As regras são só IPv4: o script recusa a rede do Docker com IPv6 ligado (NAT64, worker#161).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
MARKER_DIR=/run/avant-firewall
MIN_ALLOW_PREFIX=24
MAX_PREFIX=32
MAX_PORT=65535
MAX_OCTET=255

# Mostra o erro e encerra.
die() { echo "firewall-saida: $*" >&2; exit 1; }
# Mostra uma linha de progresso.
log() { echo "firewall-saida: $*"; }

# Lê uma variável do vm.env do ambiente.
vm_env_value() {
  local variable="$1"
  grep -E "^$variable=" "$ROOT/compose/$ENV_NAME/vm.env" | tail -n 1 | cut -d= -f2-
}

# Diz se o texto é um IPv4 com octetos de 0 a 255.
valid_ipv4() {
  local address="$1" octet
  local -a octets
  [[ "$address" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
  IFS=. read -r -a octets <<< "$address"
  for octet in "${octets[@]}"; do
    (( 10#$octet <= MAX_OCTET )) || return 1
  done
}

# Recusa AVANT_EGRESS_ALLOW fora do formato, com porta fora de 1-65535 ou rede larga demais.
validate_allow_list() {
  local allowed address port prefix
  for allowed in ${AVANT_EGRESS_ALLOW:-}; do
    [[ "$allowed" =~ ^([0-9.]+)(/([0-9]{1,2}))?:([0-9]{1,5})$ ]] \
      || die "AVANT_EGRESS_ALLOW inválido: $allowed (use ip:porta ou ip/prefixo:porta)"
    address="${BASH_REMATCH[1]}"
    prefix="${BASH_REMATCH[3]:-$MAX_PREFIX}"
    port="${BASH_REMATCH[4]}"
    valid_ipv4 "$address" || die "AVANT_EGRESS_ALLOW com IP inválido: $allowed"
    (( 10#$prefix >= MIN_ALLOW_PREFIX && 10#$prefix <= MAX_PREFIX )) \
      || die "AVANT_EGRESS_ALLOW com rede larga demais: $allowed (prefixo de $MIN_ALLOW_PREFIX a $MAX_PREFIX)"
    (( 10#$port >= 1 && 10#$port <= MAX_PORT )) || die "AVANT_EGRESS_ALLOW com porta inválida: $allowed"
  done
}

# Recusa a rede do Docker que já existe com outra bridge ou com IPv6. Sem a rede, segue: as
# regras usam o nome fixo da bridge e passam a valer quando ela for criada.
check_network() {
  local network="$1" bridge="$2" current_bridge ipv6_enabled
  docker network inspect "$network" >/dev/null 2>&1 || return 0
  current_bridge="$(docker network inspect -f '{{index .Options "com.docker.network.bridge.name"}}' "$network")"
  [[ "$current_bridge" == "$bridge" ]] \
    || die "a rede $network usa a bridge '$current_bridge', não $bridge: recrie a rede (README, \"Rede com subnet fixa\")"
  ipv6_enabled="$(docker network inspect -f '{{.EnableIPv6}}' "$network")"
  [[ "$ipv6_enabled" == false ]] || die "a rede $network tem IPv6 ligado; as regras daqui são só IPv4"
}

# Lista os servidores DNS que o Docker repassa aos containers (fora os de loopback).
dns_servers() {
  local resolv_conf=/etc/resolv.conf
  [[ -f "$SYSTEMD_RESOLV_CONF" ]] && resolv_conf="$SYSTEMD_RESOLV_CONF"
  awk '$1 == "nameserver" && $2 ~ /^[0-9.]+$/ && $2 !~ /^127\./ { print $2 }' "$resolv_conf"
}

# Escreve as exceções comuns às duas chains: conexões já abertas, DNS e AVANT_EGRESS_ALLOW.
exception_rules() {
  local chain="$1" dns_server allowed
  echo "-A $chain -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN"
  for dns_server in $(dns_servers); do
    echo "-A $chain -d $dns_server -p udp --dport 53 -j RETURN"
    echo "-A $chain -d $dns_server -p tcp --dport 53 -j RETURN"
  done
  for allowed in ${AVANT_EGRESS_ALLOW:-}; do
    echo "-A $chain -p tcp -m conntrack --ctorigdst ${allowed%:*} --ctorigdstport ${allowed##*:} -j RETURN"
  done
}

# Escreve o comando que apaga cada salto antigo de uma chain do sistema para a nossa.
remove_jump_rules() {
  local parent_chain="$1" chain="$2" current_rules rule
  current_rules="$(iptables -S "$parent_chain")"
  while read -r rule; do
    if [[ "$rule" == "-A $parent_chain "*"-j $chain" ]]; then
      echo "${rule/-A /-D }"
    fi
  done <<< "$current_rules"
}

# Monta a transação inteira do iptables-restore (chains novas, saltos antigos fora, saltos novos).
ruleset() {
  local bridge="$1" forward_chain="$2" input_chain="$3" blocked_network
  echo "*filter"
  echo ":$forward_chain - [0:0]"
  echo ":$input_chain - [0:0]"
  exception_rules "$forward_chain"
  echo "-A $forward_chain -o $bridge -j RETURN"
  for blocked_network in "${BLOCKED_NETWORKS[@]}"; do
    echo "-A $forward_chain -d $blocked_network -j DROP"
  done
  exception_rules "$input_chain"
  echo "-A $input_chain -j DROP"
  remove_jump_rules DOCKER-USER "$forward_chain"
  remove_jump_rules INPUT "$input_chain"
  echo "-I DOCKER-USER 1 -i $bridge -j $forward_chain"
  echo "-I INPUT 1 -i $bridge -j $input_chain"
  echo "COMMIT"
}

# Aplica as regras numa transação só e grava a bridge para o deploy.sh conferir.
apply() {
  local bridge="$1" forward_chain="$2" input_chain="$3" rules
  rules="$(ruleset "$bridge" "$forward_chain" "$input_chain")"
  iptables-restore --noflush <<< "$rules" \
    || die "o iptables recusou as regras novas; nada mudou e as anteriores continuam"
  mkdir -p "$MARKER_DIR"
  echo "$bridge" > "$MARKER_DIR/$ENV_NAME"
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
    BRIDGE="$(vm_env_value AVANT_BRIDGE)"
    [[ "$BRIDGE" =~ ^[a-z0-9-]{1,15}$ ]] || die "AVANT_BRIDGE inválido em compose/$ENV_NAME/vm.env: '$BRIDGE'"
    validate_allow_list
    check_network "avant-$ENV_NAME" "$BRIDGE"
    apply "$BRIDGE" "$FORWARD_CHAIN" "$INPUT_CHAIN"
    ;;
  status)
    iptables -S DOCKER-USER
    iptables -S "$FORWARD_CHAIN"
    iptables -S "$INPUT_CHAIN"
    ;;
  *) die "ação desconhecida: $ACTION" ;;
esac
