---
name: avant-deploy-vm
description: Use ao mudar o compose das VMs, o nginx, o script de deploy ou o monitoramento no avant-infra, e para validar antes do PR.
---

# Mudanças no avant-infra

Regras fixas (não trocar):
- A aplicação conecta como `avant_app` (sem BYPASSRLS); só o serviço `migrate` usa `avant_owner`.
- Produção: mínimo de 2 instâncias de `api` e de `web`, blue-green. Staging: 1 de cada, na VM menor.
- `/api/v1/events` com `proxy_buffering off` em todo proxy. `/api/v1/metrics` nunca exposto para a internet.
- Segredos só em `/srv/avant/<ambiente>/` na VM. Variável nova entra no `.env.example` só com o nome.
- Comentários e documentação em português.

## Validar sem VM

O repositório não tem CI. Antes do PR:

```bash
T=$(mktemp -d)
printf 'POSTGRES_SUPERUSER_PASSWORD=a\nAVANT_OWNER_PASSWORD=b\nAVANT_APP_PASSWORD=c\nRABBITMQ_PASSWORD=d\n' > $T/compose.env
touch $T/app.env $T/gam-service-account.json
printf 'API_BLUE_TAG=1\nWEB_BLUE_TAG=1\nWORKER_TAG=1\nMIGRATE_TAG=1\n' > $T/release.env
for e in staging production; do
  sed "s|^AVANT_STATE_DIR=.*|AVANT_STATE_DIR=$T|" compose/$e/vm.env > $T/vm.env
  docker compose -f compose/vm/docker-compose.yml --env-file $T/vm.env \
    --env-file $T/compose.env --env-file $T/release.env --profile blue --profile tools config -q
done
shellcheck scripts/*.sh
```

## Deploy

`scripts/deploy.sh <staging|production> up | api <tag> | web <tag> | worker <tag> | rollback api|web | status`. Detalhes no README. Produção só com o Pedro.
