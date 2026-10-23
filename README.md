# avant-infra

Infraestrutura do Groone Avant: como os serviços rodam juntos em cada ambiente.

| Pasta | Conteúdo |
| --- | --- |
| `compose/local` | Postgres, RabbitMQ e Redis para desenvolvimento, e os serviços do Avant no perfil `app` |
| `compose/staging`, `compose/production` | ambientes das VMs (em construção) |
| `postgres/init` | papéis do banco: `avant_owner` (migrations) e `avant_app` (aplicação, sujeita ao RLS) |
| `nginx` | proxy: `/` para o Vue, `/api` para o FastAPI, SSE sem buffer |
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

## Segredos

Nenhum segredo entra no Git. O `.env.example` traz só os nomes das variáveis. Em staging e produção os valores ficam nas VMs.
