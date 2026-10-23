# avant-infra

Infraestrutura do Groone Avant: como os serviços rodam juntos em cada ambiente.

| Pasta | Conteúdo |
| --- | --- |
| `compose/local` | Postgres, RabbitMQ e Redis para desenvolvimento, e os serviços do Avant no perfil `app` |
| `compose/vm` | compose único das VMs, com blue-green de `api` e `web` |
| `compose/staging`, `compose/production` | o que muda por ambiente (`vm.env`, sem segredos) |
| `scripts/deploy.sh` | deploy, troca de cor e rollback nas VMs |
| `postgres/init` | papéis do banco: `avant_owner` (migrations) e `avant_app` (aplicação, sujeita ao RLS) |
| `nginx` | proxy local (`avant.conf`), proxy do stack nas VMs (`vm.conf`) e modelo do nginx do host com TLS (`host/`) |
| `monitoring` | Prometheus (e depois Loki e painéis do Grafana) |
| `jenkins` | biblioteca compartilhada dos Jenkinsfiles (em construção) |

Repositórios do Avant: `avant-core`, `avant-api`, `avant-worker`, `avant-web`, `avant-infra`.

## Rodar localmente

Clone os repositórios do Avant lado a lado na mesma pasta e, dentro de `avant-infra`:

```sh
cp .env.example .env          # preencha as senhas
docker compose -f compose/local/docker-compose.yml --env-file .env up -d
```

Isso sobe só Postgres, RabbitMQ e Redis. Para subir também API, worker, scheduler, web e nginx (em `http://localhost:8080`), quando esses repositórios existirem localmente:

```sh
docker compose -f compose/local/docker-compose.yml --env-file .env --profile app up -d
```

## VMs (staging e produção)

Produção roda na VM principal (que também tem Genius, Data e MongoDB) e staging na VM menor. As duas usam `compose/vm/docker-compose.yml`; o que muda está em `compose/<ambiente>/vm.env`.

```
nginx do host (TLS, avant.groone.com / staging.avant.groone.com)
  └─ 127.0.0.1:8080 (produção) ou 127.0.0.1:8081 (staging)
       └─ nginx do stack ─┬─ /api  → api-blue | api-green   (2 réplicas em produção)
                          └─ /     → web-blue | web-green   (2 réplicas em produção)
  worker (filas default, mail) · worker-gam (fila gam) · scheduler (beat, sempre 1)
  postgres · rabbitmq · redis
```

- A aplicação conecta como `avant_app` (sem BYPASSRLS). Só o serviço `migrate` recebe a senha do `avant_owner`.
- `/api/v1/events` passa sem buffer nos dois nginx. `/api/v1/metrics` responde 404 para fora; o Prometheus lê pela rede interna.
- O modelo do nginx do host está em `nginx/host/avant.conf.example` (certificados pelo certbot).

### Arquivos na VM

Em `/srv/avant/<ambiente>/` (dono `root`, permissão `600` nos arquivos):

| Arquivo | Quem escreve | Conteúdo |
| --- | --- | --- |
| `compose.env` | Pedro | senhas do Postgres e do RabbitMQ (nomes no `.env.example`) |
| `app.env` | Pedro | segredos da aplicação: sessão, 2FA, Resend, Google, GAM |
| `gam-service-account.json` | Pedro | chave da conta de serviço do GAM, montada só no `worker-gam` |
| `release.env` | `deploy.sh` | cor ativa e tag de cada serviço |
| `upstreams/*.conf` | `deploy.sh` | para qual cor o nginx manda o tráfego |

### Deploy

```sh
scripts/deploy.sh staging up                # Postgres, RabbitMQ, Redis, nginx e o que já estiver ativo
scripts/deploy.sh staging api <tag>         # migrations com a imagem nova, depois blue-green da API
scripts/deploy.sh staging web <tag>         # blue-green do painel
scripts/deploy.sh staging worker <tag>      # worker, worker-gam e scheduler
scripts/deploy.sh staging rollback api      # volta para a cor anterior (fica parada, pronta)
scripts/deploy.sh staging status
```

O blue-green sobe a cor nova, espera o healthcheck de todas as réplicas, troca o upstream do nginx (com `nginx -t` antes; se falhar, nada muda), espera as conexões saírem e para a cor antiga. As migrations rodam antes da troca, então precisam funcionar com a versão anterior ainda no ar: adicionar coluna num deploy, remover a antiga só no seguinte.

### Primeiro boot

1. Criar `/srv/avant/<ambiente>/` com `compose.env`, `app.env` e `gam-service-account.json`.
2. Fazer login no GHCR com um token só de leitura de pacotes.
3. `scripts/deploy.sh <ambiente> up`, depois `api`, `web` e `worker` com as tags.
4. Criar a Empresa interna da Groone e o primeiro usuário com o `avant-bootstrap` do avant-core, dentro de um container da API.
5. Configurar o nginx do host a partir de `nginx/host/avant.conf.example`.

## Segredos

Nenhum segredo entra no Git. O `.env.example` traz só os nomes das variáveis. Em staging e produção os valores ficam nas VMs.
