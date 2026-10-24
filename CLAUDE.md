# avant-infra

Infraestrutura do Groone Avant (docker compose, nginx, Postgres, monitoramento, Jenkins).

- Nunca commitar segredos. Variáveis novas entram no `.env.example` só com o nome.
- A aplicação conecta ao Postgres como `avant_app`, que não é dono das tabelas e não tem BYPASSRLS. Migrations usam `avant_owner`. Não trocar isso: o Row Level Security depende disso.
- Produção: mínimo de 2 instâncias de `api` e de `web`, deploy blue-green. Staging: 1 de cada, na VM menor.
- O endpoint `/api/v1/events` (SSE) precisa de `proxy_buffering off` em qualquer proxy.
- `/api/v1/metrics` nunca exposto para a internet.
- Branches: trabalho em `feat/...` ou `fix/...` a partir de `develop`, PR para `develop`. `develop` publica em staging e `main` em produção.
- Textos de documentação e comentários em português.
- Clean code obrigatório também nos scripts (skill `avant-clean-code`): nomes claros, nada de
  variável de uma letra, um comentário de 1 ou 2 linhas acima de cada função, nada de
  comentário ao lado do código. Sem CI aqui: confira à mão antes do merge.

## Contexto, issues e skills

- Comece por `docs/contexto.md`: produto, decisões, estado dos cinco repositórios e onde está cada coisa. Decisões antigas em `docs/decisoes/`.
- Todo trabalho parte de uma issue com milestone neste repositório (`gh issue list --milestone ...`). Pedido sem issue vira issue antes.
- Skills em `docs/skills/` (índice em `docs/skills/README.md`); `.claude/skills` aponta para lá. Comece pela `avant-fluxo-de-trabalho`.
- Grafo do código em `graphify-out/` (comece pelo `GRAPH_REPORT.md`, ou `graphify query "..."`). Mudou código: `graphify update .` e commite o grafo no mesmo PR.
