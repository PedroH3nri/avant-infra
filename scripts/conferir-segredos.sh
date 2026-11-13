#!/usr/bin/env bash
# Confere os arquivos de segredo de uma VM: cada um precisa existir, ter permissão 600 ou 400 e
# pertencer ao dono esperado (nome ou uid). Usado pelo deploy.sh e antes do up do Jenkins.
#
#   scripts/conferir-segredos.sh <dono> <arquivo>...
#   scripts/conferir-segredos.sh avant-deploy /srv/avant/staging/compose.env /srv/avant/staging/app.env
#   scripts/conferir-segredos.sh 1000 /srv/jenkins/secrets/*
set -euo pipefail

ALLOWED_MODES=(600 400)

# Mostra o erro e encerra.
die() { echo "conferir-segredos: $*" >&2; exit 1; }

# Diz se a permissão está entre as aceitas (só o dono lê; ninguém mais).
allowed_mode() {
  local mode="$1" allowed
  for allowed in "${ALLOWED_MODES[@]}"; do
    [[ "$mode" == "$allowed" ]] && return 0
  done
  return 1
}

# Confere um arquivo de segredo: existência, permissão e dono.
check_secret() {
  local expected_owner="$1" secret_file="$2" mode owner_name owner_id
  [[ -f "$secret_file" ]] || die "faltou $secret_file"
  read -r mode owner_name owner_id < <(stat -c '%a %U %u' "$secret_file")
  allowed_mode "$mode" || die "$secret_file está com permissão $mode; use chmod 600 (ou 400)"
  [[ "$owner_name" == "$expected_owner" || "$owner_id" == "$expected_owner" ]] \
    || die "$secret_file pertence a $owner_name (uid $owner_id); o dono precisa ser $expected_owner"
}

[[ $# -ge 2 ]] || die "uso: $0 <dono> <arquivo>..."
EXPECTED_OWNER="$1"
shift
for secret_file in "$@"; do
  check_secret "$EXPECTED_OWNER" "$secret_file"
done
