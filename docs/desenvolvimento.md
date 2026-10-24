# Rodar o Avant em modo de desenvolvimento

Este guia sobe o Avant inteiro na sua máquina: Postgres, RabbitMQ e Redis pelo Docker, e API, worker e painel direto no terminal, com recarga automática. Leva uns 15 minutos na primeira vez.

```
navegador → http://localhost:5173  (Vite, avant-web)
               └─ /api → http://localhost:8000  (uvicorn, avant-api)
                            ├─ Postgres :5432  (papel avant_app, com RLS)
                            ├─ Redis    :6379  (limites, travas, eventos do SSE)
                            └─ RabbitMQ :5672 ─→ worker e scheduler (avant-worker)
```

## 1. O que instalar

| Ferramenta | Versão | Para quê |
| --- | --- | --- |
| Docker com Compose | 24 ou mais | Postgres 16, RabbitMQ 3.13 e Redis 7 |
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

## 3. Subir Postgres, RabbitMQ e Redis

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
docker compose -f compose/local/docker-compose.yml --env-file .env ps   # os três "healthy"
```

Na primeira subida, o `postgres/init/01-roles.sh` cria o banco `avant` e os dois papéis:

- `avant_owner`, dono das tabelas, usado só nas migrations;
- `avant_app`, usado pela API e pelo worker, sem BYPASSRLS. É ele que faz o Row Level Security valer, então nunca rode a aplicação como `avant_owner` ou `postgres`.

O painel do RabbitMQ fica em http://localhost:15672 (usuário `avant`).

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
```

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
| `RESEND_API_KEY` | nenhum e-mail sai. O envio vai para o log da API, com o link (convite, nova senha) |
| `GOOGLE_OAUTH_CLIENT_ID` e `_SECRET` | o botão "Entrar com Google" responde `google_unavailable` |
| `GAM_SERVICE_ACCOUNT_FILE` e `GAM_GROONE_NETWORK_CODE` | as tarefas da fila `gam` falham com "defina GAM_SERVICE_ACCOUNT_FILE..." e a network fica com erro. O resto do painel funciona |

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
uv run uvicorn avant_api.main:create_app --factory --reload --port 8000
```

Para conferir: http://localhost:8000/api/v1/ready responde `{"status":"ok","checks":{"database":"ok"}}`. A documentação OpenAPI fica em http://localhost:8000/api/docs.

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
AVANT_API_URL=http://localhost:8000 pnpm dev
```

Abra http://localhost:5173. O Vite repassa `/api` para a API, então o painel e a API ficam na mesma origem, como em produção, e o cookie de sessão e o CSRF funcionam sem configuração extra. Em `AVANT_ENV=local` o cookie não leva `Secure`, então `http://` funciona.

## 9. Primeiro acesso

1. Entre em `/entrar` com o e-mail e a senha do passo 5.
2. A equipe Groone precisa de 2FA: o painel pede para configurar logo no primeiro login. Use qualquer app autenticador (Google Authenticator, 1Password etc.) e guarde os códigos de recuperação.
3. Em `/interno`, cadastre um cliente de teste. O convite de dono não vai por e-mail: o link aparece no log da API, na linha `convite enviado`. Abra o link numa janela anônima para criar a conta e a Empresa do cliente.
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
uv run --no-sync uvicorn avant_api.main:create_app --factory --reload --port 8000
uv run --no-sync pytest
```

Use `--no-sync` enquanto estiver testando: um `uv run` sem ele (ou um `uv sync`) volta para a versão da tag. Nada disso muda o `pyproject.toml` ou o `uv.lock`, então não há o que desfazer antes do commit. Quando o core estiver pronto: PR no core subindo a `version`, o merge em `develop` cria a tag, e então um PR na API e no worker apontando para a tag nova (skill `avant-lancar-versao`).

## 12. Problemas comuns

| Sintoma | Causa e solução |
| --- | --- |
| `uv sync` da API ou do worker falha ao baixar o `avant-core` | o git não autentica no GitHub: `gh auth login` |
| `relation "companies" does not exist` (no bootstrap ou na API) | as migrations não rodaram nesse banco: `uv run alembic upgrade head` no avant-core (passo 5). O Postgres do Docker cria só o banco vazio e os papéis |
| A API não sobe: `database_url` ou `mfa_encryption_key` "Field required" | o `dev.env` não foi carregado neste terminal |
| Login responde 403 `mfa_required` em tudo | a equipe Groone precisa configurar o 2FA; o painel leva para essa tela |
| Tabelas aparecem vazias ou `permission denied` | rodou a aplicação como `avant_owner`/`postgres`, ou criou um banco sem os privilégios do passo 10 |
| O painel mostra erro de rede em toda chamada | a API não está na porta 8000, ou faltou `AVANT_API_URL` no `pnpm dev` |
| O SSE (avisos em tempo real) não chega | o worker publica no Redis: confira o `REDIS_URL` nos dois lados |
| Quero começar do zero | `docker compose -f compose/local/docker-compose.yml --env-file .env down -v` apaga os volumes; refaça a partir do passo 3 |

## Perfil `app` do compose

O `compose/local/docker-compose.yml` tem um perfil `app`, que sobe API, worker, scheduler, painel e nginx em containers. Ele ainda não serve para desenvolver: o build da API e do worker precisa do secret do GitHub, não roda as migrations e o nginx local aponta para a porta errada do painel. Até isso ser corrigido, use o caminho deste guia. A correção está na [issue #16](https://github.com/PedroH3nri/avant-infra/issues/16).
