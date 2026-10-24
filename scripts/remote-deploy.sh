#!/usr/bin/env bash
# Comando forçado da chave SSH do Jenkins nas VMs (command= no authorized_keys do avant-deploy).
# Confere o pedido do Jenkins, atualiza esta cópia do avant-infra e chama o deploy.sh ou o backup.
#
#   command="/opt/avant-infra/staging/scripts/remote-deploy.sh staging develop",restrict ssh-ed25519 AAAA... jenkins
#
# Argumentos fixos no authorized_keys: o único ambiente que a chave pode tocar nesta VM e a
# branch do avant-infra que ele segue (staging: develop, production: main).
# Pedidos aceitos (SSH_ORIGINAL_COMMAND): "<ambiente> api|web|worker <tag>" e "<ambiente> backup".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Mostra o erro e encerra sem fazer nada.
die() { echo "remote-deploy: $*" >&2; exit 1; }

# Valida o pedido e só então troca o código do avant-infra e chama o deploy.
main() {
  local allowed_env="${1:-}" infra_branch="${2:-}" env_name action tag
  local -a request
  [[ -n "$allowed_env" && -n "$infra_branch" ]] || die "uso no authorized_keys: $0 <ambiente> <branch do avant-infra>"
  read -r -a request <<< "${SSH_ORIGINAL_COMMAND:-}"
  (( ${#request[@]} >= 2 && ${#request[@]} <= 3 )) || die "pedido inválido: '${SSH_ORIGINAL_COMMAND:-}'"
  env_name="${request[0]}"; action="${request[1]}"; tag="${request[2]:-}"
  [[ "$env_name" == "$allowed_env" ]] || die "esta chave só faz deploy de $allowed_env"
  case "$action" in
    api|web|worker) [[ "$tag" =~ ^[A-Za-z0-9_.-]{1,128}$ ]] || die "tag inválida: '$tag'" ;;
    backup) [[ -z "$tag" ]] || die "backup não recebe argumento" ;;
    *) die "ação não permitida: $action" ;;
  esac

  git -C "$ROOT" fetch --quiet origin "$infra_branch"
  git -C "$ROOT" checkout --quiet --detach FETCH_HEAD
  echo "remote-deploy: avant-infra em $(git -C "$ROOT" rev-parse --short HEAD) ($infra_branch)"

  if [[ "$action" == backup ]]; then
    [[ -x "$ROOT/scripts/backup.sh" ]] || die "backup ainda não configurado (scripts/backup.sh, issue #7 do avant-infra); o deploy de produção espera por ele"
    exec "$ROOT/scripts/backup.sh" "$env_name"
  fi
  exec "$ROOT/scripts/deploy.sh" "$env_name" "$action" "$tag"
}

main "$@"
