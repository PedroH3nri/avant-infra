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

# Mostra o erro e encerra o deploy.
die() { echo "deploy: $*" >&2; exit 1; }
# Mostra uma linha de progresso do deploy.
log() { echo "deploy: $*"; }

[[ $# -ge 2 ]] || die "uso: $0 <staging|production> <up|api|web|worker|rollback|status> [tag|serviço]"
ENV_NAME="$1"; ACTION="$2"; ARG="${3:-}"
case "$ENV_NAME" in staging|production) ;; *) die "ambiente desconhecido: $ENV_NAME" ;; esac

VM_ENV="$ROOT/compose/$ENV_NAME/vm.env"
[[ -f "$VM_ENV" ]] || die "faltou $VM_ENV"
STATE_DIR="$(grep -E '^AVANT_STATE_DIR=' "$VM_ENV" | cut -d= -f2-)"
[[ -n "$STATE_DIR" ]] || die "AVANT_STATE_DIR vazio em $VM_ENV"
for secret_file in compose.env app.env; do
  [[ -f "$STATE_DIR/$secret_file" ]] || die "faltou $STATE_DIR/$secret_file (segredos da VM)"
done
RELEASE="$STATE_DIR/release.env"
mkdir -p "$STATE_DIR/upstreams"
touch "$RELEASE"

# Um deploy por vez em cada ambiente.
exec 9>"$STATE_DIR/deploy.lock"
flock -n 9 || die "outro deploy de $ENV_NAME está rodando"

# Roda o docker compose da VM com as variáveis do ambiente, os segredos e o release.
compose() {
  docker compose -f "$ROOT/compose/vm/docker-compose.yml" \
    --env-file "$VM_ENV" --env-file "$STATE_DIR/compose.env" --env-file "$RELEASE" "$@"
}

# Lê uma variável do release.env (vazio quando não existe).
get() { grep -E "^$1=" "$RELEASE" | tail -n1 | cut -d= -f2- || true; }
# Grava uma variável no release.env, trocando o arquivo de uma vez.
set_var() {
  local key="$1" value="$2" temp_file
  temp_file="$(mktemp "$STATE_DIR/.release.XXXXXX")"
  grep -vE "^$key=" "$RELEASE" > "$temp_file" || true
  echo "$key=$value" >> "$temp_file"
  mv "$temp_file" "$RELEASE"
}

# Recusa a tag de imagem com caracteres fora do padrão.
valid_tag() { [[ "$1" =~ ^[A-Za-z0-9_.-]{1,128}$ ]] || die "tag inválida: $1"; }
# Devolve a outra cor do blue-green.
other() { [[ "$1" == blue ]] && echo green || echo blue; }
# Converte o texto para maiúsculas.
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }

# Escreve o upstream do nginx apontando o serviço para uma cor.
write_upstream() {
  local service="$1" color="$2" port file
  case "$service" in api) port=8000 ;; web) port=8080 ;; esac
  file="$STATE_DIR/upstreams/$service.conf"
  cat > "$file.tmp" <<CONF
# Escrito por scripts/deploy.sh em $(date -u +%FT%TZ). Não editar.
upstream avant_$service {
    zone avant_$service 64k;
    server $service-$color:$port resolve;
    keepalive 16;
}
CONF
  mv "$file.tmp" "$file"
}

# Troca o upstream e recarrega; se o nginx recusar a configuração, volta o arquivo antigo.
point_nginx() {
  local service="$1" color="$2" file="$STATE_DIR/upstreams/$1.conf"
  [[ -f "$file" ]] && cp "$file" "$file.bak"
  write_upstream "$service" "$color"
  if ! compose exec -T nginx nginx -t >/dev/null 2>&1; then
    [[ -f "$file.bak" ]] && mv "$file.bak" "$file"
    die "nginx -t recusou o upstream novo de $service; o tráfego continua na cor anterior"
  fi
  compose exec -T nginx nginx -s reload
}

# Espera todas as réplicas do serviço ficarem healthy (healthcheck da imagem).
wait_healthy() {
  local service="$1" deadline=$((SECONDS + HEALTH_TIMEOUT)) states
  while (( SECONDS < deadline )); do
    states="$(compose ps --all --format '{{.Health}}' "$service" 2>/dev/null | sort -u | tr '\n' ' ')"
    if [[ "$states" == "healthy " ]]; then
      log "$service saudável"
      return 0
    fi
    if [[ "$states" == *unhealthy* ]]; then break; fi
    sleep 3
  done
  compose logs --tail 80 "$service" >&2 || true
  die "$service não ficou saudável em ${HEALTH_TIMEOUT}s (estados: ${states:-nenhum})"
}

# Sobe Postgres, RabbitMQ, Redis e nginx, criando os upstreams que faltarem.
ensure_base() {
  compose up -d postgres rabbitmq redis
  for colored_service in api web; do
    [[ -f "$STATE_DIR/upstreams/$colored_service.conf" ]] || write_upstream "$colored_service" "${ACTIVE:-blue}"
  done
  compose up -d nginx
}

# Blue-green: sobe a cor parada com a tag nova, espera ficar saudável, troca o nginx e
# para a cor antiga (que fica criada, para o rollback).
switch_to() {
  local service="$1" color="$2" old
  old="$(get "$(upper "$service")_ACTIVE")"
  compose up -d --no-deps "$service-$color"
  wait_healthy "$service-$color"
  point_nginx "$service" "$color"
  set_var "$(upper "$service")_ACTIVE" "$color"
  log "$service agora na cor $color"
  if [[ -n "$old" && "$old" != "$color" ]]; then
    sleep "$DRAIN_SECONDS"
    compose stop "$service-$old"
    log "$service-$old parado (rollback: $0 $ENV_NAME rollback $service)"
  fi
}

# Publica a tag na cor parada: puxa a imagem, roda as migrations (api) e troca a cor.
deploy_color() {
  local service="$1" tag="$2" active next
  valid_tag "$tag"
  active="$(get "$(upper "$service")_ACTIVE")"
  next="$(other "${active:-green}")"
  set_var "$(upper "$service")_$(upper "$next")_TAG" "$tag"
  compose pull "$service-$next"
  ensure_base
  if [[ "$service" == api ]]; then
    set_var MIGRATE_TAG "$tag"
    log "migrations com avant-api:$tag"
    compose run --rm migrate
  fi
  switch_to "$service" "$next"
}

case "$ACTION" in
  up)
    ACTIVE=blue ensure_base
    for service in api web; do
      color="$(get "$(upper "$service")_ACTIVE")"
      if [[ -n "$color" ]]; then compose up -d --no-deps "$service-$color"; fi
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
