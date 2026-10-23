# avant-infra

Infraestrutura do Groone Avant (docker compose, nginx, Postgres, monitoramento, Jenkins).

- Nunca commitar segredos. Variáveis novas entram no `.env.example` só com o nome.
- A aplicação conecta ao Postgres como `avant_app`, que não é dono das tabelas e não tem BYPASSRLS. Migrations usam `avant_owner`. Não trocar isso: o Row Level Security depende disso.
- Produção: mínimo de 2 instâncias de `api` e de `web`, deploy blue-green. Staging: 1 de cada, na VM menor.
- O endpoint `/api/v1/events` (SSE) precisa de `proxy_buffering off` em qualquer proxy.
- `/api/v1/metrics` nunca exposto para a internet.
- Branches: trabalho em `feat/...` ou `fix/...` a partir de `develop`, PR para `develop`. `develop` publica em staging e `main` em produção.
- Textos de documentação e comentários em português.
