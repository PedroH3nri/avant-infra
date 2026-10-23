#!/bin/sh
# Cria os dois papéis do banco do Avant.
#
# avant_owner: dono das tabelas; usado só pelas migrations (Alembic).
# avant_app:   usado pela API e pelo worker em tempo de execução. Não é dono
#              das tabelas e não tem BYPASSRLS, então o Row Level Security vale
#              para ele. Superusuários e donos de tabela ignoram o RLS por padrão.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
CREATE ROLE avant_owner LOGIN PASSWORD '${AVANT_OWNER_PASSWORD}';
CREATE ROLE avant_app LOGIN PASSWORD '${AVANT_APP_PASSWORD}' NOBYPASSRLS;

ALTER DATABASE ${POSTGRES_DB} OWNER TO avant_owner;
ALTER SCHEMA public OWNER TO avant_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO avant_app;

-- Toda tabela criada pelas migrations já nasce com acesso para a aplicação.
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO avant_app;
SQL
