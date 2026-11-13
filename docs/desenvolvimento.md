# Rodar o Avant em modo de desenvolvimento

Este guia sobe o Avant inteiro na sua máquina: Postgres, RabbitMQ, Redis e Mailpit pelo Docker, e API, worker e painel direto no terminal, com recarga automática. Leva uns 15 minutos na primeira vez.

O painel abre em `http://localhost:5173`, sem nginx e sem certificado. Os cookies de sessão continuam sempre `Secure` e `__Host-`, como em staging e produção: o Chrome e o Firefox aceitam esses cookies em `http://localhost` (e em `http://127.0.0.1`), que contam como contexto seguro. O Safari não aceita: para testar nele, ou para reproduzir o caminho da VM, ligue o HTTPS local (seção "HTTPS local (opcional)", no fim).

```
navegador → http://localhost:5173  (Vite, avant-web)
               └─ /api → http://127.0.0.1:8000  (proxy do Vite → uvicorn, avant-api)
                            ├─ Postgres :5432  (papel avant_app, com RLS)
                            ├─ Redis    :6379  (limites, travas, eventos do SSE)
                            ├─ RabbitMQ :5672 ─→ worker e scheduler (avant-worker)
                            └─ Mailpit  :1025  (e-mails, vistos em http://localhost:8025)
```

## 1. O que instalar

| Ferramenta | Versão | Para quê |
| --- | --- | --- |
| Docker com Compose | 24 ou mais | Postgres 16, RabbitMQ 3.13, Redis 7 e Mailpit |
| [mkcert](https://github.com/FiloSottile/mkcert) (opcional) | 1.4 ou mais | só para o HTTPS local (`https://avant.localhost`) |
| [uv](https://docs.astral.sh/uv/) | 0.5 ou mais | Python 3.12 (o uv baixa sozinho) e dependências do core, da API e do worker |
| Node.js e pnpm | Node 24, pnpm 10.28 (o `packageManager` do avant-web) | painel Vue |
| git e acesso ao GitHub | | o avant-core é privado e a API e o worker o instalam por tag do Git |
| graphify (opcional) | `uv tool install graphifyy` | atualizar o grafo do código (`graphify update .`) |

No macOS (Intel ou Apple Silicon), pelo Homebrew:

```bash
brew install uv node@24     # siga o aviso do brew para pôr o node@24 no PATH
corepack enable             # vem com o Node; usa o pnpm do packageManager
```

Em Linux: `curl -LsSf https://astral.sh/uv/install.sh | sh` para o uv e o Node 24 pelo gerenciador que preferir (nvm, fnm, mise), depois `corepack enable`. Confira com `uv --version` e, dentro do `avant-web`, `pnpm --version` (10.28.0).

O `uv sync` da API e do worker baixa o avant-core pelo GitHub. Se o seu git ainda não autentica no GitHub, rode `gh auth login` (ou configure uma chave SSH) antes.

## 2. Clonar os cinco repositórios lado a lado

O compose local procura os outros repositórios na mesma pasta.

```bash
mkdir avant && cd avant
for r in avant-core avant-api avant-worker avant-web avant-infra; do
  git clone -b develop https://github.com/PedroH3nri/$r.git
done
```

## 3. Subir Postgres, RabbitMQ, Redis e Mailpit

```bash
cd avant-infra
cp .env.example .env
```

No `.env`, preencha só as senhas do Postgres e do RabbitMQ. Em desenvolvimento qualquer valor serve, mas não reaproveite senhas de staging ou produção:

```dotenv
POSTGRES_SUPERUSER_PASSWORD=dev_postgres
AVANT_OWNER_PASSWORD=dev_owner
AVANT_APP_PASSWORD=dev_app
RABBITMQ_PASSWORD=dev_rabbit
```

```bash
docker compose -f compose/local/docker-compose.yml --env-file .env up -d
# Os quatro "healthy".
docker compose -f compose/local/docker-compose.yml --env-file .env ps
```

Na primeira subida, o `postgres/init/01-roles.sh` cria o banco `avant` e os dois papéis:

- `avant_owner`, dono das tabelas, usado só nas migrations;
- `avant_app`, usado pela API e pelo worker, sem BYPASSRLS. É ele que faz o Row Level Security valer, então nunca rode a aplicação como `avant_owner` ou `postgres`.

O painel do RabbitMQ fica em http://localhost:15672 (usuário `avant`).

O Mailpit recebe por SMTP em `localhost:1025` e mostra os e-mails em http://localhost:8025. As duas portas ficam só no loopback.

## 4. Variáveis da aplicação

A API e o worker rodam fora do Docker, então falam com `localhost`, e não com os nomes `postgres`, `rabbitmq` e `redis` do `.env.example`. Crie um `dev.env` fora dos repositórios (por exemplo em `avant/dev.env`, na pasta de cima) e troque as senhas pelas do passo 3:

```dotenv
AVANT_ENV=local
DATABASE_URL=postgresql+psycopg://avant_app:dev_app@localhost:5432/avant
DATABASE_MIGRATIONS_URL=postgresql+psycopg://avant_owner:dev_owner@localhost:5432/avant
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=amqp://avant:dev_rabbit@localhost:5672//
APP_BASE_URL=http://localhost:5173
MFA_ENCRYPTION_KEY=
MAIL_TRANSPORT=smtp
SMTP_URL=smtp://localhost:1025
MAIL_FROM="Avant <avant@localhost>"
FORWARDED_ALLOW_IPS=127.0.0.1
```

`FORWARDED_ALLOW_IPS` diz de quem a API aceita `X-Forwarded-For` (e com ele o IP de quem chama, que sustenta os limites de tentativas). É obrigatória em todo ambiente, só com IPs ou redes, nunca `*`: sem ela, a API não sobe. No caminho padrão quem chega ao uvicorn é o proxy do Vite, por `127.0.0.1`. Com o HTTPS local, o nginx do compose também chega por `127.0.0.1` no macOS; no Linux, por `10.250.0.10` (veja a seção do HTTPS local).

`REDIS_URL`, `CELERY_BROKER_URL` e `MAIL_TRANSPORT` são obrigatórias em todo ambiente: sem qualquer uma delas, a API e o worker não sobem. Mantenha as aspas do `MAIL_FROM` (o `<` quebra o `source` sem elas).

**E-mail.** `MAIL_TRANSPORT` não tem padrão: `smtp` (exige `SMTP_URL`) ou `resend` (exige `RESEND_API_KEY`). No desenvolvimento é `smtp`, para o Mailpit que sobe no passo 3: todo e-mail que a API e o worker mandam (convite, nova senha, avisos) fica na caixa dele, em http://localhost:8025, para qualquer endereço, e nada sai para a internet. Não precisa de conta no Resend. Staging e produção usam `resend` (ver o README, "Arquivos na VM"). Nenhum link com token vai para o log, em nenhum ambiente.

Gere a `MFA_ENCRYPTION_KEY` uma vez e cole no arquivo. Se trocar a chave, o 2FA de quem já configurou para de funcionar:

```bash
cd avant-core && uv run python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Sem o uv ainda, o openssl gera uma chave equivalente: `openssl rand -base64 32 | tr '+/' '-_'` (44 caracteres, terminando em `=`).

Em cada terminal dos passos seguintes, carregue o arquivo antes de rodar os comandos:

```bash
set -a; . ../dev.env; set +a
```

O que fica de fora em desenvolvimento, e o que acontece sem cada variável:

| Variável | Sem ela |
| --- | --- |
| `GOOGLE_OAUTH_CLIENT_ID` e `_SECRET` | o botão "Entrar com Google" responde `google_unavailable` |
| `GAM_SERVICE_ACCOUNT_FILE` e `GAM_GROONE_NETWORK_CODE` | as tarefas da fila `gam` falham com "defina GAM_SERVICE_ACCOUNT_FILE..." e a network fica com erro. O resto do painel funciona |
| `PAGE_VIEWS_MONGO_URL` | o agendador não sincroniza as visitas e a tela Page Views fica vazia. Use um usuário só de leitura no Mongo do iGroone/data |
| `GEOLITE2_COUNTRY_FILE` | o país das visitas da tag do Avant fica `unknown` (as visitas são gravadas do mesmo jeito). Nas VMs: baixe a base GeoLite2 Country da MaxMind (conta grátis) para `/srv/avant/<ambiente>/geoip/GeoLite2-Country.mmdb`, ponha `GEOLITE2_COUNTRY_FILE=/geoip/GeoLite2-Country.mmdb` no `app.env` e atualize o arquivo toda semana (por exemplo com o `geoipupdate` da MaxMind num cron do host). O worker lê a base ao subir: depois de trocar o arquivo, reinicie o `worker` |
| `OPENEXCHANGERATES_APP_ID` | o agendador não busca cotações e o painel só mostra dólar (as outras moedas aparecem desabilitadas em Configurações → Conta) |

Para testar o GAM de verdade, peça ao Pedro a chave da conta de serviço. Guarde fora dos repositórios e aponte `GAM_SERVICE_ACCOUNT_FILE` para ela só no terminal do worker.

## 5. Migrations e primeiro usuário

```bash
cd avant-core
uv sync
set -a; . ../dev.env; set +a
uv run alembic upgrade head
AVANT_BOOTSTRAP_PASSWORD='uma-senha-forte-local' uv run avant-bootstrap voce@groone.com "Seu Nome"
```

O `avant-bootstrap` cria a Company Groone (a Empresa interna) com você como dono e os papéis `groone_admin` e `groone_support`. Rode uma vez por banco: se rodar de novo, ele avisa que a Company já existe.

Para as telas não ficarem vazias, preencha o banco com dados de demonstração (só funciona com `AVANT_ENV=local`, que já está no `dev.env`):

```bash
AVANT_DEMO_PASSWORD='uma-senha-forte-local' uv run avant-seed-demo voce@groone.com
```

Ele cria a Empresa "Portal Notícias (demo)" com você como dono: equipe com papéis variados, convites pendentes, duas networks (uma com erro), sites e ad units. No painel interno aparecem mais dois clientes, um convite de dono e dois MCM sem dono. As pessoas de demonstração têm e-mail `@example.com` e entram com a senha de `AVANT_DEMO_PASSWORD` (sem ela, só aparecem nas listas). Roda uma vez por banco. Para recomeçar do zero, apague o banco e refaça este passo.

## 6. API

```bash
cd avant-api
uv sync
set -a; . ../dev.env; set +a
uv run uvicorn avant_api.main:create_app --factory --reload --host 127.0.0.1 --port 8000 \
  --proxy-headers
```

O `--proxy-headers` é o mesmo da imagem da API: o uvicorn lê o `X-Forwarded-For` e o `X-Forwarded-Proto` do proxy, mas só de quem estiver no `FORWARDED_ALLOW_IPS` do `dev.env` (passo 4), que ele lê sozinho. Não passe `--forwarded-allow-ips` na linha de comando: ele passa por cima da variável.

Para conferir: http://localhost:8000/api/v1/ready responde `{"status":"ok","checks":{"database":"ok"}}`.

## 7. Worker e scheduler

Dois terminais, no `avant-worker`:

```bash
cd avant-worker
uv sync
set -a; . ../dev.env; set +a
uv run celery -A avant_worker.app worker -Q default,mail,gam -l info
```

```bash
cd avant-worker
set -a; . ../dev.env; set +a
uv run celery -A avant_worker.app beat -l info
```

Em desenvolvimento, um worker só atende as três filas. Nas VMs, a fila `gam` tem um worker próprio, o único com a chave do GAM. O scheduler só é preciso para testar as tarefas agendadas (descoberta do MCM, importações, limpeza). Sem ele, "sincronizar agora" e conectar uma network continuam funcionando, porque a API manda a tarefa direto para a fila.

## 8. Painel

```bash
cd avant-web
pnpm install
pnpm dev
```

Abra **http://localhost:5173** no Chrome ou no Firefox. O Vite repassa `/api` para a API em `127.0.0.1:8000`, então o painel e a API ficam na mesma origem, como em produção, e o cookie de sessão (`Secure`, `__Host-`) e o CSRF funcionam. No Safari o login não fica: use o HTTPS local.

## 9. Primeiro acesso

1. Abra http://localhost:5173/entrar e entre com o e-mail e a senha do passo 5.
2. A equipe Groone precisa de 2FA: o painel pede para configurar logo no primeiro login. Use qualquer app autenticador (Google Authenticator, 1Password etc.) e guarde os códigos de recuperação.
3. Em `/interno`, cadastre um cliente de teste com qualquer e-mail. O convite de dono aparece no Mailpit, em http://localhost:8025. Abra o link numa janela anônima para criar a conta e a Empresa do cliente.
4. Na Empresa do cliente você testa equipe, papéis, convites, networks, sites e chaves de API.
5. Com os dados de demonstração, troque para "Portal Notícias (demo)" no seletor de Empresa e as telas já vêm preenchidas.

## 10. Testes

Os testes de integração usam um banco separado, `avant_test`, que eles apagam e recriam a cada rodada. Crie esse banco uma vez, com os mesmos privilégios do `avant`:

```bash
cd avant-infra
docker compose -f compose/local/docker-compose.yml --env-file .env exec -T postgres \
  sh -c 'psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE avant_test OWNER avant_owner" &&
         psql -U "$POSTGRES_USER" -d avant_test -v ON_ERROR_STOP=1' <<'SQL'
ALTER SCHEMA public OWNER TO avant_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO avant_app;
SQL
```

Sem os `ALTER DEFAULT PRIVILEGES` nesse banco, os testes falham com `permission denied for table users`.

Depois, em cada repositório Python:

```bash
export AVANT_TEST_MIGRATIONS_URL=postgresql+psycopg://avant_owner:dev_owner@localhost:5432/avant_test
export AVANT_TEST_DATABASE_URL=postgresql+psycopg://avant_app:dev_app@localhost:5432/avant_test
export AVANT_TEST_REDIS_URL=redis://localhost:6379/15   # API e worker; opcional
uv run ruff format . && uv run ruff check . && uv run mypy && uv run pytest
```

Sem as variáveis `AVANT_TEST_*`, os testes de integração são pulados e só os unitários rodam. No painel:

```bash
pnpm lint && pnpm typecheck && pnpm test && pnpm build
```

Esses são os mesmos comandos do CI, e precisam passar antes de abrir o PR.

## 11. Mudando o avant-core junto com a API ou o worker

A API e o worker instalam o core por tag (`pyproject.toml`). Para testar uma mudança do core antes de lançar a versão, instale a sua cópia local por cima, só no ambiente:

```bash
cd avant-api
uv pip install -e ../avant-core
uv run --no-sync uvicorn avant_api.main:create_app --factory --reload --host 127.0.0.1 --port 8000 \
  --proxy-headers
uv run --no-sync pytest
```

Use `--no-sync` enquanto estiver testando: um `uv run` sem ele (ou um `uv sync`) volta para a versão da tag. Nada disso muda o `pyproject.toml` ou o `uv.lock`, então não há o que desfazer antes do commit. Quando o core estiver pronto: PR no core subindo a `version`, o merge em `develop` cria a tag, e então um PR na API e no worker apontando para a tag nova (skill `avant-lancar-versao`).

## 12. Problemas comuns

| Sintoma | Causa e solução |
| --- | --- |
| `uv sync` da API ou do worker falha ao baixar o `avant-core` | o git não autentica no GitHub: `gh auth login` |
| `relation "companies" does not exist` (no bootstrap ou na API) | as migrations não rodaram nesse banco: `uv run alembic upgrade head` no avant-core (passo 5). O Postgres do Docker cria só o banco vazio e os papéis |
| A API ou o worker não sobe: `configuração ... incompleta: DATABASE_URL, MFA_ENCRYPTION_KEY, ...` (muitos nomes) | o `dev.env` não foi carregado neste terminal (`set -a; . ../dev.env; set +a`) |
| A API não sobe: `configuração da API incompleta: NOMES` | faltam no `dev.env` as variáveis listadas (passo 4). Os nomes são os das variáveis, em maiúsculas; o valor nunca aparece |
| O worker não sobe: `configuração do worker incompleta: NOMES` | o mesmo, no terminal do worker |
| O e-mail do convite não aparece no Mailpit | o Mailpit não está de pé (`docker compose ... ps`), ou o `dev.env` não tem `MAIL_TRANSPORT=smtp` e `SMTP_URL=smtp://localhost:1025`. O convite da API vai pela fila `mail`: confira também o worker |
| Login responde 403 `mfa_required` em tudo | a equipe Groone precisa configurar o 2FA; o painel leva para essa tela |
| Tabelas aparecem vazias ou `permission denied` | rodou a aplicação como `avant_owner`/`postgres`, ou criou um banco sem os privilégios do passo 10 |
| O painel mostra erro de rede em toda chamada | a API não está em `127.0.0.1:8000` |
| O login responde certo, mas a sessão não fica | no Safari, os cookies `Secure` não valem em `http://localhost`: use o Chrome ou o Firefox, ou o HTTPS local |
| A API não sobe: `configuração da API incompleta: FORWARDED_ALLOW_IPS` | falta o `FORWARDED_ALLOW_IPS` no `dev.env`, ou ele está com `*` ou com algo que não é IP ou rede (passo 4) |
| Com o HTTPS local, o IP das sessões aparece como o do nginx | o `FORWARDED_ALLOW_IPS` não bate com o endereço do nginx: `127.0.0.1` no macOS, `127.0.0.1,10.250.0.10` no Linux |
| `docker compose up` diz que a rede `avant_default` "needs to be recreated" | a rede ganhou subnet fixa: `docker compose -f compose/local/docker-compose.yml --env-file .env down` (sem `-v`, os dados ficam) e suba de novo |
| O SSE (avisos em tempo real) não chega | o worker publica no Redis: confira o `REDIS_URL` nos dois lados |
| Quero começar do zero | `docker compose -f compose/local/docker-compose.yml --env-file .env down -v` apaga os volumes; refaça a partir do passo 3 |

## HTTPS local (opcional)

Para testar no Safari, ou para reproduzir o caminho da VM (nginx na frente, com os mesmos limites por IP e o mesmo log sem tokens), o compose tem o perfil `https`: um nginx em `https://avant.localhost` com um certificado do mkcert. Fica desligado por padrão.

**Certificado (uma vez por máquina).** O mkcert cria uma autoridade certificadora (CA) só sua, instala no sistema e no Firefox, e emite o certificado de `avant.localhost`. A chave da CA e o certificado ficam só na sua máquina: o `.certs/` está no `.gitignore` e nada disso vai para o repositório.

```bash
brew install mkcert nss
mkcert -install
cd avant-infra
mkdir -p .certs
mkcert -cert-file .certs/avant.localhost.pem -key-file .certs/avant.localhost-key.pem avant.localhost
```

- No Linux, o mkcert vem do gerenciador de pacotes (`apt install mkcert libnss3-tools`) ou da página de releases dele.
- O `mkcert -install` pede a senha do computador (macOS) ou o `sudo` (Linux) para instalar a CA. Feche e abra o navegador depois.
- Chrome, Edge e Safari usam a CA do sistema; o Firefox usa a dele, e o `nss` é o que deixa o mkcert instalar lá também.
- Os navegadores resolvem `*.localhost` sozinhos. Para o `curl` e outras ferramentas, se `avant.localhost` não resolver, ponha `127.0.0.1 avant.localhost` no `/etc/hosts`.
- Nunca compartilhe o `rootCA-key.pem` (fica em `mkcert -CAROOT`): quem tem essa chave emite certificados que a sua máquina aceita. Para desfazer: `mkcert -uninstall`.

**Subir.** Com a API e o Vite rodando como nos passos 6 e 8:

```bash
docker compose -f compose/local/docker-compose.yml --env-file .env --profile https up -d nginx
```

Troque `APP_BASE_URL=https://avant.localhost` no `dev.env`, reinicie a API e o worker e abra **https://avant.localhost**. O nginx escuta em `127.0.0.1:443` (o `:80` só redireciona), manda `/` para o Vite e `/api` para a API, repassa `X-Forwarded-Proto https` e o IP de quem chamou, e a recarga do Vite passa por `wss://avant.localhost`. Para voltar ao padrão, `docker compose ... --profile https stop nginx` e `APP_BASE_URL=http://localhost:5173`.

| Sintoma | Causa e solução |
| --- | --- |
| O navegador diz que o certificado não é confiável | faltou o `mkcert -install`, ou o navegador estava aberto: feche e abra. No Firefox, faltou o `nss` |
| O nginx não sobe: `cannot load certificate "/etc/nginx/certs/avant.localhost.pem"` | faltou gerar o certificado em `avant-infra/.certs/` |
| `https://avant.localhost` responde 502 | o Vite ou a API não está rodando |
| No Linux, 502 em tudo | o `host.docker.internal` é o `172.17.0.1` do Docker: rode o uvicorn e o Vite com `--host 172.17.0.1` (`AVANT_DEV_HOST=172.17.0.1 pnpm dev`) e ponha `FORWARDED_ALLOW_IPS=127.0.0.1,10.250.0.10` no `dev.env` (no Linux o nginx chega com o IP fixo dele) |

## Perfil `app` do compose

O `compose/local/docker-compose.yml` tem um perfil `app`, que sobe API, worker, scheduler e painel em containers, atrás do nginx com HTTPS (suba com `--profile app --profile https`, com o certificado da seção acima e, no `.env`, `AVANT_API_UPSTREAM=api:8000`, `AVANT_WEB_UPSTREAM=web:8080` e `APP_BASE_URL=https://avant.localhost`: o padrão do `.env` aponta para o Vite, e os links dos e-mails sairiam errados). A API em container recebe `FORWARDED_ALLOW_IPS` com o IP fixo do nginx (`AVANT_LOCAL_NGINX_IP`). O build da API e do worker usa um token do GitHub como secret: `GITHUB_TOKEN="$(gh auth token)" docker compose -f compose/local/docker-compose.yml --env-file .env --profile app build`. Ele ainda não serve para desenvolver: não roda as migrations. Até isso ser corrigido, use o caminho deste guia. A correção está na [issue #16](https://github.com/PedroH3nri/avant-infra/issues/16).
