#!/usr/bin/env bash
# Confere a subnet fixa da rede Docker do stack antes do deploy (rodado pelo deploy.sh).
#
#   scripts/conferir-subnet.sh <subnet> <rede>
#   scripts/conferir-subnet.sh 10.201.1.0/24 avant-staging
#
# Se a rede já existe, ela precisa estar com essa subnet (senão, falta recriá-la; ver README).
# Se ainda não existe, a subnet não pode se sobrepor a nenhuma rota IPv4 da VM nem a nenhuma
# outra rede Docker.
set -euo pipefail

# Mostra o erro e encerra.
die() { echo "conferir-subnet: $*" >&2; exit 1; }

# Converte um IPv4 em número inteiro.
ip_to_number() {
  local address="$1" first second third fourth
  IFS=. read -r first second third fourth <<< "$address"
  echo $(( (first << 24) + (second << 16) + (third << 8) + fourth ))
}

# Devolve o primeiro e o último endereço (como números) de uma rede no formato ip/prefixo.
network_range() {
  local network="$1" address prefix start size
  address="${network%/*}"
  prefix="${network#*/}"
  [[ "$network" == */* ]] || prefix=32
  size=$(( 1 << (32 - prefix) ))
  start=$(( $(ip_to_number "$address") / size * size ))
  echo "$start $(( start + size - 1 ))"
}

# Diz se duas redes ip/prefixo têm algum endereço em comum.
overlaps() {
  local first_start first_end second_start second_end
  read -r first_start first_end < <(network_range "$1")
  read -r second_start second_end < <(network_range "$2")
  (( first_start <= second_end && second_start <= first_end ))
}

# Lista as redes de destino das rotas IPv4 da VM (sem a rota padrão).
route_networks() {
  ip -4 route show | awk '$1 != "default" && $1 ~ /^[0-9.]+(\/[0-9]+)?$/ { print $1 }'
}

# Lista as subnets IPv4 das redes Docker, menos a do próprio stack.
docker_networks() {
  local own_network="$1" network_name
  for network_name in $(docker network ls --format '{{.Name}}'); do
    [[ "$network_name" == "$own_network" ]] && continue
    docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' "$network_name" \
      | tr ' ' '\n' | grep -E '^[0-9.]+/[0-9]+$' | sed "s|\$| $network_name|" || true
  done
}

[[ $# -eq 2 ]] || die "uso: $0 <subnet> <rede>"
SUBNET="$1"
NETWORK="$2"
[[ "$SUBNET" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] || die "subnet inválida: $SUBNET"

if CURRENT="$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' "$NETWORK" 2>/dev/null)"; then
  [[ " $CURRENT " == *" $SUBNET "* ]] \
    || die "a rede $NETWORK existe com a subnet ${CURRENT% }, não $SUBNET: recrie a rede (README, \"Rede com subnet fixa\")"
  exit 0
fi

for route in $(route_networks); do
  if overlaps "$SUBNET" "$route"; then
    die "a subnet $SUBNET se sobrepõe à rota $route da VM: escolha outra em compose/<ambiente>/vm.env"
  fi
done
while read -r docker_subnet docker_name; do
  [[ -n "$docker_subnet" ]] || continue
  if overlaps "$SUBNET" "$docker_subnet"; then
    die "a subnet $SUBNET se sobrepõe à rede Docker $docker_name ($docker_subnet): escolha outra em compose/<ambiente>/vm.env"
  fi
done < <(docker_networks "$NETWORK")
