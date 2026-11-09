# avant-infra

Infraestrutura do Groone Avant: como os serviços rodam juntos em cada ambiente.

| Pasta | Conteúdo |
| --- | --- |
| `compose/local` | Postgres, RabbitMQ e Redis para desenvolvimento, e os serviços do Avant no perfil `app` |
| `compose/vm` | compose único das VMs, com blue-green de `api` e `web` |
| `compose/staging`, `compose/production` | o que muda por ambiente (`vm.env`, sem segredos) |
| `scripts/deploy.sh` | deploy, troca de cor e rollback nas VMs |
| `scripts/remote-deploy.sh` | comando forçado da chave SSH do Jenkins: confere o pedido e chama o `deploy.sh` |
| `postgres/init` | papéis do banco: `avant_owner` (migrations) e `avant_app` (aplicação, sujeita ao RLS) |
| `nginx` | proxy local (`avant.conf`), proxy do stack nas VMs (`vm.conf`) e modelo do nginx do host com TLS (`host/`) |
| `monitoring` | Prometheus (e depois Loki e painéis do Grafana) |
| `jenkins` | biblioteca compartilhada dos Jenkinsfiles e como preparar as VMs para o deploy ([`jenkins/README.md`](jenkins/README.md)) |
| `compose/jenkins` | o Jenkins da VM pequena, configurado pelo repositório (Configuration as Code) |

Repositórios do Avant: `avant-core`, `avant-api`, `avant-worker`, `avant-web`, `avant-infra`.

## Rodar localmente

O passo a passo completo do modo de desenvolvimento (serviços no Docker, API, worker e painel no terminal, primeiro usuário e testes) está em [`docs/desenvolvimento.md`](docs/desenvolvimento.md).

Resumo: com os cinco repositórios clonados lado a lado, dentro de `avant-infra`:

```sh
cp .env.example .env          # preencha as senhas
docker compose -f compose/local/docker-compose.yml --env-file .env up -d
```

Isso sobe Postgres, RabbitMQ e Redis. O perfil `app`, que sobe também a aplicação em containers, ainda não funciona ([#16](https://github.com/PedroH3nri/avant-infra/issues/16)).

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
- `/reward.js` (do avant-web) sai com `Access-Control-Allow-Origin: *` e cache de 10 minutos; `/api/reward/*` (rotas públicas do reward, chamadas dos sites dos clientes) vai para a API com corpo de até 16 KB.
- O modelo do nginx do host está em `nginx/host/avant.conf.example` (certificados pelo certbot).

### Arquivos na VM

Em `/srv/avant/<ambiente>/` (dono `avant-deploy`, o usuário do deploy, permissão `600` nos arquivos):

| Arquivo | Quem escreve | Conteúdo |
| --- | --- | --- |
| `compose.env` | Pedro | senhas do Postgres, do RabbitMQ e do Redis (nomes no `.env.example`) |
| `app.env` | Pedro | segredos da aplicação: sessão, 2FA, Resend, Google, GAM |
| `gam-service-account.json` | Pedro | chave da conta de serviço do GAM, montada só no `worker-gam` |
| `release.env` | `deploy.sh` | cor ativa e tag de cada serviço |
| `upstreams/*.conf` | `deploy.sh` | para qual cor o nginx manda o tráfego |

### Deploy

O Jenkins faz o deploy sozinho a cada merge em `develop` (staging) e em `main` (produção), por SSH, com uma chave que só roda `scripts/remote-deploy.sh` ([`jenkins/README.md`](jenkins/README.md)). À mão, na VM:

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

1. Preparar o usuário `avant-deploy`, a cópia do avant-infra em `/opt/avant-infra/<ambiente>` e a chave do Jenkins ([`jenkins/README.md`](jenkins/README.md#preparar-uma-vm-para-receber-deploy)).
2. Criar `/srv/avant/<ambiente>/` com `compose.env`, `app.env` e `gam-service-account.json`.
3. `scripts/deploy.sh <ambiente> up`. Depois disso cada merge publica sozinho; para o primeiro deploy, rode os jobs `develop` dos três serviços no Jenkins (API primeiro, por causa das migrations).
4. Criar a Empresa interna da Groone e o primeiro usuário com o `avant-bootstrap` do avant-core, dentro de um container da API.
5. Configurar o nginx do host a partir de `nginx/host/avant.conf.example`.

### Redis com senha (uma vez por ambiente)

Desde avant-infra#68 o Redis exige senha. O primeiro deploy depois disso recria o Redis com a
senha, mas a API ativa e os workers continuam com a URL antiga, sem senha, até serem recriados:
login, chave de API, relatórios e as travas do worker dão erro nesse meio tempo. Por isso, em
cada ambiente, numa janela combinada e antes do primeiro deploy pelo Jenkins:

1. Pôr `REDIS_PASSWORD=` (só letras e números) em `/srv/avant/<ambiente>/compose.env`.
2. Rodar na VM `scripts/deploy.sh <ambiente> up`, que recria a base, a cor ativa da API e do
   painel e os workers de uma vez, já com a URL nova.

O Postgres, o RabbitMQ e o nginx também reiniciam nesse `up` (mudaram os tetos de memória e de
CPU): são alguns segundos fora do ar.

### Papéis do Postgres (uma vez por banco que já existe)

Desde avant-infra#60 e #64 as senhas do Postgres entram como secrets do compose (precisa do
Docker Compose 2.23 ou mais novo) e o `avant_app` tem `statement_timeout` e
`idle_in_transaction_session_timeout` de 5 minutos. O `postgres/init/01-roles.sh` só roda na
criação do banco; num banco que já existe (staging ou o seu local), rodar uma vez:

```bash
docker compose ... exec postgres psql -U postgres -d avant -c \
  "ALTER ROLE avant_app SET statement_timeout = '5min'" -c \
  "ALTER ROLE avant_app SET idle_in_transaction_session_timeout = '5min'"
```

Num ambiente novo, se o `01-roles.sh` parar (secret de senha vazio ou ausente), o volume
`postgres-data` fica meio inicializado: no `up` seguinte o Postgres sobe sem os papéis e não roda
o init de novo. Corrija o secret, apague o volume (sem dados ainda) e suba de novo.

Troque `-U postgres -d avant` se `POSTGRES_SUPERUSER` ou `POSTGRES_DB` forem outros no
`compose.env`. O `ALTER ROLE` só vale para conexões novas: as conexões da API e dos workers pegam
o timeout depois que eles forem recriados (o `up` abaixo resolve isso).

### Imagens com digest e Postgres com secrets (uma vez por ambiente)

Desde avant-infra#64, as imagens da base têm digest e o Postgres recebe as senhas por secrets. O
primeiro deploy depois disso recria o Postgres, o RabbitMQ, o Redis e o nginx, porque o deploy de
qualquer serviço chama a base. A cor ativa da API e os workers ficam alguns segundos sem banco e
sem fila, e tarefas do Celery em andamento podem falhar. Por isso, em cada ambiente, numa janela
combinada e antes do primeiro deploy pelo Jenkins:

1. Conferir na VM que `docker compose version` é 2.23 ou mais novo. Com um Compose mais velho,
   o `secrets: environment:` é recusado na leitura do arquivo e todo `deploy.sh` falha.
2. Conferir que `POSTGRES_SUPERUSER_PASSWORD`, `AVANT_OWNER_PASSWORD` e `AVANT_APP_PASSWORD` estão
   em `/srv/avant/<ambiente>/compose.env`.
3. Rodar na VM `scripts/deploy.sh <ambiente> up`, que recria a base, a cor ativa da API e do
   painel e os workers de uma vez.
4. Rodar o SQL dos papéis acima, se ainda não rodou nesse banco.

## Segredos

Nenhum segredo entra no Git. O `.env.example` traz só os nomes das variáveis. Em staging e produção os valores ficam nas VMs.
