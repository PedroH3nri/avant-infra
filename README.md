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
- `/tag.js` e `/reward.js` (do avant-web, gerados do avant-tag) saem com `Access-Control-Allow-Origin: *` e cache de 10 minutos; `/api/reward/*` e `/api/tag/*` (rotas públicas do reward e da ad tag, chamadas dos sites dos clientes) vão para a API com corpo de até 16 KB.
- O modelo do nginx do host está em `nginx/host/avant.conf.example` (certificados pelo certbot).
- Os três nginx (host, stack da VM e local) gravam o `access_log` no formato `avant_redacted`, que troca por `***` os tokens de convite e de nova senha da URL e do Referer. O `error_log` de cada `server` fica em `crit`: o erro do upstream (502) gravaria a linha da requisição com o token, e o `error_log` não tem formato. O 502 continua no `access_log` (status), e a causa nos logs da api.

### Arquivos na VM

Em `/srv/avant/<ambiente>/`, permissão `600` ou `400` nos arquivos. O dono é o `avant-deploy` (o usuário do deploy), menos a chave do GAM: ela é montada como secret (bind mount) no `worker-gam`, que roda como o uid `10001`, então fica com dono `10001` e permissão `400` (`sudo chown 10001 gam-service-account.json && sudo chmod 400 gam-service-account.json`). O `deploy.sh` confere o dono e a permissão arquivo por arquivo com o `scripts/conferir-segredos.sh` e para se algum estiver fora. Para conferir a leitura: `docker exec avant-<ambiente>-worker-gam-1 cat /run/secrets/gam-service-account.json`.

| Arquivo | Quem escreve | Conteúdo |
| --- | --- | --- |
| `compose.env` | Pedro | senhas do Postgres, do RabbitMQ e do Redis (nomes no `.env.example`) |
| `app.env` | Pedro | segredos da aplicação: sessão, 2FA, e-mail (`MAIL_TRANSPORT=resend` e `RESEND_API_KEY`: sem eles o `deploy.sh` para), Google, GAM |
| `gam-service-account.json` | Pedro | chave da conta de serviço do GAM, montada só no `worker-gam` (dono `10001`, permissão `400`) |
| `geoip/GeoLite2-Country.mmdb` | Pedro (ou o `geoipupdate`) | base de países da MaxMind para o país das visitas da ad tag, montada só leitura no `worker` (país das visitas) e na `api` (país dos floors das regras de preço) |
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
   Pôr também a base GeoLite2 (ver "Base GeoLite2" abaixo).
3. Ligar o firewall de saída dos containers (ver "Firewall de saída" abaixo): o `deploy.sh` não
   sobe nada sem ele.
4. `scripts/deploy.sh <ambiente> up`. Depois disso cada merge publica sozinho; para o primeiro deploy, rode os jobs `develop` dos três serviços no Jenkins (API primeiro, por causa das migrations).
5. Criar a Empresa interna da Groone e o primeiro usuário com o `avant-bootstrap` do avant-core, dentro de um container da API.
6. Configurar o nginx do host a partir de `nginx/host/avant.conf.example`.

### Rede com subnet fixa (uma vez por ambiente)

A api só aceita `X-Forwarded-For` do nginx do stack (`FORWARDED_ALLOW_IPS`, obrigatória e sem
`*`, avant-api#301), então a rede `avant-<ambiente>` tem subnet, gateway e faixa dinâmica fixas e
o nginx um IP fixo, fora da faixa dinâmica. Tudo em `compose/<ambiente>/vm.env`:

| Variável | Produção | Staging | Para quê |
| --- | --- | --- | --- |
| `AVANT_SUBNET` | `10.201.0.0/24` | `10.201.1.0/24` | rede do stack |
| `AVANT_GATEWAY_IP` | `10.201.0.1` | `10.201.1.1` | de onde chega o nginx do host (`set_real_ip_from` do `vm.conf`) |
| `AVANT_NGINX_IP` | `10.201.0.10` | `10.201.1.10` | `FORWARDED_ALLOW_IPS` da api |
| `AVANT_DYNAMIC_IP_RANGE` | `10.201.0.128/25` | `10.201.1.128/25` | IPs dos outros containers |
| `AVANT_BRIDGE` | `avant-prod` | `avant-stg` | nome fixo da bridge (até 15 letras), usado pelo firewall de saída |

Antes de criar a rede, o `deploy.sh` roda `scripts/conferir-subnet.sh`, que recusa a subnet se ela
se sobrepuser a uma rota IPv4 da VM (`ip -4 route`) ou a outra rede Docker (Genius, Data,
Jenkins). Se recusar, escolha outra faixa e troque as quatro variáveis de endereço juntas. O
prefixo da subnet vai de `/8` a `/30`.

Numa VM que já tem a rede antiga (sem subnet fixa ou sem a bridge com nome fixo), o `deploy.sh`
para e pede para recriá-la.
Numa janela combinada (alguns minutos fora do ar; os volumes ficam):

```bash
cd /opt/avant-infra/<ambiente>
docker compose -f compose/vm/docker-compose.yml --env-file compose/<ambiente>/vm.env \
  --env-file /srv/avant/<ambiente>/compose.env --env-file /srv/avant/<ambiente>/release.env \
  --profile '*' down
systemctl restart avant-firewall-<ambiente>
scripts/deploy.sh <ambiente> up
```

O `up` cria a rede nova, com a bridge `AVANT_BRIDGE`, sobe o nginx com o IP fixo e a cor ativa da
api com o `FORWARDED_ALLOW_IPS`. Com a bridge de nome fixo, um `down`/`up` depois disso não pede
mais para reaplicar o firewall.
O `vm.conf` agora é um template do nginx: mudanças nele só valem quando o container do nginx é
recriado (`docker compose ... up -d --force-recreate nginx`), não com um `reload`.

### Firewall de saída (uma vez por VM)

A api e o worker buscam URLs que vêm de fora (ícones, sites dos clientes): sem firewall, uma
URL que resolve para um endereço interno chega na rede da VM ou nos metadados da nuvem (SSRF;
avant-infra#114, avant-worker#161). O `scripts/firewall-saida.sh` fecha isso no iptables:

- os containers da rede `avant-<ambiente>` não abrem conexão nova para `10.0.0.0/8`,
  `172.16.0.0/12`, `192.168.0.0/16` (RFC 1918), `100.64.0.0/10`, `169.254.0.0/16` (link-local e
  metadados, `169.254.169.254`), `0.0.0.0/8`, `198.18.0.0/15`, multicast e reservados, nem para o
  próprio host;
- continuam liberados: a própria rede do Docker (Postgres, Redis, RabbitMQ e o nginx do stack),
  o DNS da VM (lido do `resolv.conf`, só a porta 53) e o que estiver em `AVANT_EGRESS_ALLOW`.

O que a VM precisa de verdade além disso entra em `AVANT_EGRESS_ALLOW`, no formato `ip:porta` ou
`ip/prefixo:porta` (prefixo de `/24` a `/32`, porta de 1 a 65535; o script recusa o resto, como
`0.0.0.0/0:443`). Por exemplo o MongoDB do iGroone/data: `AVANT_EGRESS_ALLOW="10.0.0.5:27017"`.
A regra casa o destino **original** da conexão (`conntrack --ctorigdst`), antes do DNAT: para um
serviço com porta publicada no host (o Mongo num container de outro compose), vale o IP do host
e a porta publicada, não o IP do container. Confira na VM, de dentro do worker, que o Mongo
responde e que outro endereço privado não. A rede do Docker precisa ficar sem IPv6 (o padrão): as
regras são só IPv4, e o script recusa a rede com IPv6 ligado.

As regras casam a bridge pelo nome fixo (`AVANT_BRIDGE` do `vm.env`), então podem ser aplicadas
antes de a rede existir e sobrevivem a um `down`/`up`. Entram numa transação só
(`iptables-restore --noflush`): se o iptables recusar qualquer linha, nada muda e as regras
anteriores, com os DROPs, continuam. Depois de aplicar, o script grava a bridge em
`/run/avant-firewall/<ambiente>`, e o `deploy.sh` para se ela não bater com o `AVANT_BRIDGE`
(firewall desligado, ou a VM reiniciou e a unit não rodou).

Como root, antes do primeiro `scripts/deploy.sh <ambiente> up`:

```bash
cat > /etc/default/avant-firewall-staging <<'ENV'
AVANT_EGRESS_ALLOW=""
ENV
cat > /etc/systemd/system/avant-firewall-staging.service <<'UNIT'
[Unit]
Description=Firewall de saída dos containers do Avant (staging)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/default/avant-firewall-staging
ExecStart=/opt/avant-infra/staging/scripts/firewall-saida.sh staging

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now avant-firewall-staging
scripts/firewall-saida.sh staging status
```

Na produção, troque `staging` por `production` nos nomes e no caminho. As regras ficam nas chains
`AVANT-SAIDA-<ambiente>` (saltada de `DOCKER-USER`, que o Docker não apaga) e
`AVANT-HOST-<ambiente>` (saltada de `INPUT`). Para mudar o `AVANT_EGRESS_ALLOW`, edite o
`/etc/default/avant-firewall-<ambiente>` e rode `systemctl restart avant-firewall-<ambiente>`.

Para conferir, de dentro do worker (deve falhar por tempo esgotado):

```bash
docker exec avant-staging-worker-1 python -c \
  "import urllib.request; urllib.request.urlopen('http://169.254.169.254/', timeout=3)"
```

### Base GeoLite2 (uma vez por ambiente, atualizada toda semana)

O worker descobre o país de cada visita da ad tag (M10) pelo IP, com a base GeoLite2 Country da
MaxMind, e a api usa a mesma base para escolher os floors das regras de preço (M11) do país de quem
pede. Sem ela tudo funciona, mas o país fica `unknown` nas métricas e a tag não recebe floors. Em
cada VM:

1. Criar uma conta grátis em maxmind.com e gerar uma license key (fica só na VM, nunca no Git).
2. Baixar a base GeoLite2 Country (`.mmdb`) para
   `/srv/avant/<ambiente>/geoip/GeoLite2-Country.mmdb`. A pasta `geoip/` é criada pelo
   `deploy.sh`.
3. Pôr `GEOLITE2_COUNTRY_FILE=/geoip/GeoLite2-Country.mmdb` no `app.env`. O compose monta
   `/srv/avant/<ambiente>/geoip` em `/geoip` no `worker` e na `api`, só leitura.
4. Rodar `scripts/deploy.sh <ambiente> up` (ou o deploy do worker e da api) para os dois subirem
   lendo a base.
5. Atualizar a base toda semana, por exemplo com o `geoipupdate` da MaxMind num cron do host, e
   reiniciar o `worker` depois de trocar o arquivo, porque ele lê a base só ao subir.

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
`idle_in_transaction_session_timeout` de 5 minutos. Desde avant-infra#135 (core#370) ele também
tem um teto de conexões: 170 em produção e 85 em staging (ver "Conexões com o Postgres" abaixo).
O `postgres/init/01-roles.sh` só roda na criação do banco; num banco que já existe (staging,
produção ou o seu local), rodar uma vez, como superusuário:

```bash
docker compose ... exec postgres psql -U postgres -d avant -c \
  "ALTER ROLE avant_app SET statement_timeout = '5min'" -c \
  "ALTER ROLE avant_app SET idle_in_transaction_session_timeout = '5min'" -c \
  "ALTER ROLE avant_app CONNECTION LIMIT 85"
```

O número do `CONNECTION LIMIT` é o `POSTGRES_APP_CONNECTION_LIMIT` do `compose/<ambiente>/vm.env`:
`85` no staging e `170` na produção. Para conferir:
`docker compose ... exec postgres psql -U postgres -d avant -c "SELECT rolconnlimit FROM pg_roles WHERE rolname = 'avant_app'"`.

Num ambiente novo, se o `01-roles.sh` parar (secret de senha vazio ou ausente), o volume
`postgres-data` fica meio inicializado: no `up` seguinte o Postgres sobe sem os papéis e não roda
o init de novo. Corrija o secret, apague o volume (sem dados ainda) e suba de novo.

Troque `-U postgres -d avant` se `POSTGRES_SUPERUSER` ou `POSTGRES_DB` forem outros no
`compose.env`. O `ALTER ROLE` só vale para conexões novas: as conexões da API e dos workers pegam
o timeout depois que eles forem recriados (o `up` abaixo resolve isso).

### Conexões com o Postgres (core#370)

A api e o worker montam o engine pelo `new_engine` do core, com o mesmo pool em todo ambiente. Só
os números vêm das variáveis `DB_POOL_*`, e os testes da api e do worker conferem a conta abaixo
com o `check_connection_budget`.

| Ambiente | API | Workers | Teto do `avant_app` | `max_connections` |
| --- | --- | --- | --- | --- |
| produção | 2 instâncias x 2 cores (deploy) x 2 processos x (10 + 5) = 120 | (4 + 2) x 5 = 30 | 170 | 200 |
| staging | 1 instância x 2 cores (deploy) x 2 processos x (10 + 5) = 60 | (2 + 1) x 5 = 15 | 85 | 100 |

- **Teto do `avant_app`** (`POSTGRES_APP_CONNECTION_LIMIT`): o `01-roles.sh` aplica com `CONNECTION LIMIT`. O que fica entre ele e o `max_connections` sobra para o superusuário, o `avant_owner` (migrations) e o backup, mesmo que a aplicação vaze conexões. Num banco que já existe, o teto entra com o SQL de "Papéis do Postgres" acima.

  Ao mudar o número de instâncias, a concorrência dos workers ou o `DB_POOL_*`, refazer a conta e
  ajustar o teto e o `max_connections`.
- **TLS (`sslmode`):** hoje a api, o worker e o Postgres estão na mesma VM, na rede interna do Docker, e a conexão vai sem TLS. Isso vale para o `DATABASE_URL` padrão do compose. Se o banco sair da VM, o `DATABASE_URL` passa a levar `?sslmode=verify-full` com a CA do servidor.
- **Métricas do pool (api):**
  - `avant_db_pool_checked_out`: conexões emprestadas a pedidos;
  - `avant_db_pool_open_connections`: conexões abertas;
  - `avant_db_pool_timeouts_total`: pedidos que esperaram além do `pool_timeout`.

  O alerta (por exemplo, `increase(avant_db_pool_timeouts_total[5m]) > 0`) entra com as regras do
  Prometheus em #5.

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
