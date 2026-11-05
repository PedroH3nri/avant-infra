#!/bin/sh
# Cria os dois papéis do banco do Avant.
#
# avant_owner: dono das tabelas; usado só pelas migrations (Alembic).
# avant_app:   usado pela API e pelo worker em tempo de execução. Não é dono
#              das tabelas e não tem BYPASSRLS, então o Row Level Security vale
#              para ele. Superusuários e donos de tabela ignoram o RLS por padrão.
#
# As senhas chegam como secrets do compose (/run/secrets), não pelo ambiente do
# contêiner, e entram no SQL como variáveis do psql (:'nome'), que as citam.
# O avant_app tem timeouts padrão como rede de segurança: a API usa 30 s por
# conta própria e as tarefas longas do worker podem subir com SET LOCAL.
# Sem o secret, ou com ele vazio, o init para: o papel nunca nasce sem senha.
set -eu

owner_password="$(cat /run/secrets/avant-owner-password)"
app_password="$(cat /run/secrets/avant-app-password)"
[ -n "$owner_password" ] || { echo "secret avant-owner-password vazio" >&2; exit 1; }
[ -n "$app_password" ] || { echo "secret avant-app-password vazio" >&2; exit 1; }

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v owner_password="$owner_password" \
  -v app_password="$app_password" \
  -v database="$POSTGRES_DB" <<'SQL'
CREATE ROLE avant_owner LOGIN PASSWORD :'owner_password';
CREATE ROLE avant_app LOGIN PASSWORD :'app_password' NOBYPASSRLS;
ALTER ROLE avant_app SET statement_timeout = '5min';
ALTER ROLE avant_app SET idle_in_transaction_session_timeout = '5min';

ALTER DATABASE :"database" OWNER TO avant_owner;
ALTER SCHEMA public OWNER TO avant_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO avant_app;

-- Toda tabela criada pelas migrations já nasce com acesso para a aplicação.
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO avant_app;
SQL
