-- Papéis do banco de teste, como em postgres/init/01-roles.sh e no CI do GitHub.
-- Só para o Postgres temporário das checagens: as senhas não valem fora dele.
CREATE ROLE avant_owner LOGIN PASSWORD 'owner';
CREATE ROLE avant_app LOGIN PASSWORD 'app' NOBYPASSRLS;
CREATE DATABASE avant_test OWNER avant_owner;
\c avant_test
ALTER SCHEMA public OWNER TO avant_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO avant_app;
ALTER DEFAULT PRIVILEGES FOR ROLE avant_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO avant_app;
CREATE EXTENSION citext;
