#!/usr/bin/env bash
# Deploy do Avant numa VM (staging ou produção), rodado pelo Jenkins ou à mão.
#
#   scripts/deploy.sh <ambiente> up                 sobe Postgres, fila, Redis, nginx e as cores ativas
#   scripts/deploy.sh <ambiente> api <tag>          migrations + blue-green da API
#   scripts/deploy.sh <ambiente> web <tag>          blue-green do painel
#   scripts/deploy.sh <ambiente> worker <tag>       worker, worker-gam e scheduler (sem cor)
#   scripts/deploy.sh <ambiente> rollback api|web   volta para a cor anterior
#   scripts/deploy.sh <ambiente> status
#
# <ambiente> é staging ou production; as configurações vêm de compose/<ambiente>/vm.env.
# Na VM precisam existir, em AVANT_STATE_DIR: compose.env, app.env e
# gam-service-account.json (ver README). O release.env e os upstreams são escritos aqui.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-180}"
# Tempo para as conexões abertas (SSE e requisições longas) saírem da cor antiga.
DRAIN_SECONDS="${DRAIN_SECONDS:-20}"

die() { echo "deploy: $*" >&2; exit 1; }
log() { echo "deploy: $*"; }

[[ $# -ge 2 ]] || die "uso: $0 <staging|production> <up|api|web|worker|rollback|status> [tag|serviço]"
ENV_NAME="$1"; ACTION="$2"; ARG="${3:-}"
case "$ENV_NAME" in staging|production) ;; *) die "ambiente desconhecido: $ENV_NAME" ;; esac

VM_ENV="$ROOT/compose/$ENV_NAME/vm.env"
[[ -f "$VM_ENV" ]] || die "faltou $VM_ENV"
STATE_DIR="$(grep -E '^AVANT_STATE_DIR=' "$VM_ENV" | cut -d= -f2-)"
[[ -n "$STATE_DIR" ]] || die "AVANT_STATE_DIR vazio em $VM_ENV"
for f in compose.env app.env; do
  [[ -f "$STATE_DIR/$f" ]] || die "faltou $STATE_DIR/$f (segredos da VM)"
done
RELEASE="$STATE_DIR/release.env"
mkdir -p "$STATE_DIR/upstreams"
touch "$RELEASE"

# Um deploy por vez em cada ambiente.
exec 9>"$STATE_DIR/deploy.lock"
flock -n 9 || die "outro deploy de $ENV_NAME está rodando"

compose() {
  docker compose -f "$ROOT/compose/vm/docker-compose.yml" \
    --env-file "$VM_ENV" --env-file "$STATE_DIR/compose.env" --env-file "$RELEASE" "$@"
}

get() { grep -E "^$1=" "$RELEASE" | tail -n1 | cut -d= -f2- || true; }
set_var() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp "$STATE_DIR/.release.XXXXXX")"
  grep -vE "^$key=" "$RELEASE" > "$tmp" || true
  echo "$key=$value" >> "$tmp"
  mv "$tmp" "$RELEASE"
}

valid_tag() { [[ "$1" =~ ^[A-Za-z0-9_.-]{1,128}$ ]] || die "tag inválida: $1"; }
other() { [[ "$1" == blue ]] && echo green || echo blue; }
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }

write_upstream() {
  local svc="$1" color="$2" port file
  case "$svc" in api) port=8000 ;; web) port=8080 ;; esac
  file="$STATE_DIR/upstreams/$svc.conf"
  cat > "$file.tmp" <<CONF
# Escrito por scripts/deploy.sh em $(date -u +%FT%TZ). Não editar.
upstream avant_$svc {
    zone avant_$svc 64k;
    server $svc-$color:$port resolve;
    keepalive 16;
}
CONF
  mv "$file.tmp" "$file"
}

# Troca o upstream e recarrega; se o nginx recusar a configuração, volta o arquivo antigo.
point_nginx() {
  local svc="$1" color="$2" file="$STATE_DIR/upstreams/$1.conf"
  [[ -f "$file" ]] && cp "$file" "$file.bak"
  write_upstream "$svc" "$color"
  if ! compose exec -T nginx nginx -t >/dev/null 2>&1; then
    [[ -f "$file.bak" ]] && mv "$file.bak" "$file"
    die "nginx -t recusou o upstream novo de $svc; o tráfego continua na cor anterior"
  fi
  compose exec -T nginx nginx -s reload
}

# Espera todas as réplicas do serviço ficarem healthy (healthcheck da imagem).
wait_healthy() {
  local svc="$1" deadline=$((SECONDS + HEALTH_TIMEOUT)) states
  while (( SECONDS < deadline )); do
    states="$(compose ps --all --format '{{.Health}}' "$svc" 2>/dev/null | sort -u | tr '\n' ' ')"
    if [[ "$states" == "healthy " ]]; then
      log "$svc saudável"
      return 0
    fi
    if [[ "$states" == *unhealthy* ]]; then break; fi
    sleep 3
  done
  compose logs --tail 80 "$svc" >&2 || true
  die "$svc não ficou saudável em ${HEALTH_TIMEOUT}s (estados: ${states:-nenhum})"
}

ensure_base() {
  compose up -d postgres rabbitmq redis
  for c in api web; do
    [[ -f "$STATE_DIR/upstreams/$c.conf" ]] || write_upstream "$c" "${ACTIVE:-blue}"
  done
  compose up -d nginx
}

# Blue-green: sobe a cor parada com a tag nova, espera ficar saudável, troca o nginx e
# para a cor antiga (que fica criada, para o rollback).
switch_to() {
  local svc="$1" color="$2" old
  old="$(get "$(upper "$svc")_ACTIVE")"
  compose up -d --no-deps "$svc-$color"
  wait_healthy "$svc-$color"
  point_nginx "$svc" "$color"
  set_var "$(upper "$svc")_ACTIVE" "$color"
  log "$svc agora na cor $color"
  if [[ -n "$old" && "$old" != "$color" ]]; then
    sleep "$DRAIN_SECONDS"
    compose stop "$svc-$old"
    log "$svc-$old parado (rollback: $0 $ENV_NAME rollback $svc)"
  fi
}

deploy_color() {
  local svc="$1" tag="$2" active next
  valid_tag "$tag"
  active="$(get "$(upper "$svc")_ACTIVE")"
  next="$(other "${active:-green}")"
  set_var "$(upper "$svc")_$(upper "$next")_TAG" "$tag"
  compose pull "$svc-$next"
  ensure_base
  if [[ "$svc" == api ]]; then
    set_var MIGRATE_TAG "$tag"
    log "migrations com avant-api:$tag"
    compose run --rm migrate
  fi
  switch_to "$svc" "$next"
}

case "$ACTION" in
  up)
    ACTIVE=blue ensure_base
    for svc in api web; do
      color="$(get "$(upper "$svc")_ACTIVE")"
      if [[ -n "$color" ]]; then compose up -d --no-deps "$svc-$color"; fi
    done
    if [[ -n "$(get WORKER_TAG)" ]]; then compose up -d worker worker-gam scheduler; fi
    ;;
  api|web)
    [[ -n "$ARG" ]] || die "faltou a tag"
    deploy_color "$ACTION" "$ARG"
    ;;
  worker)
    [[ -n "$ARG" ]] || die "faltou a tag"
    valid_tag "$ARG"
    set_var WORKER_TAG "$ARG"
    compose pull worker
    ensure_base
    # O Celery termina as tarefas em andamento (stop_grace_period) e acks_late devolve o
    # resto para a fila; o scheduler troca por último para não agendar em dobro.
    compose up -d worker worker-gam
    compose up -d scheduler
    log "worker, worker-gam e scheduler em avant-worker:$ARG"
    ;;
  rollback)
    [[ "$ARG" == api || "$ARG" == web ]] || die "rollback de api ou web"
    active="$(get "$(upper "$ARG")_ACTIVE")"
    [[ -n "$active" ]] || die "$ARG ainda não teve deploy"
    back="$(other "$active")"
    back_tag="$(get "$(upper "$ARG")_$(upper "$back")_TAG")"
    [[ -n "$back_tag" ]] || die "não há versão anterior de $ARG"
    log "$ARG volta para $back, versão $back_tag (as migrations não são desfeitas)"
    switch_to "$ARG" "$back"
    ;;
  status)
    cat "$RELEASE"
    compose ps
    ;;
  *) die "ação desconhecida: $ACTION" ;;
esac
