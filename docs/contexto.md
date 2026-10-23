# Groone Avant: contexto do projeto

Contexto principal do projeto, igual nos cinco repositórios (atualizado em 23/10/2026). Quem chega para trabalhar aqui, pessoa ou agente, precisa só deste arquivo, do `CLAUDE.md`, das issues e da pasta `docs/`. Se algo aqui divergir do código, vale o código; corrija este arquivo nos cinco repositórios.

## O produto

O Groone Avant ("Avant") é um SaaS para os clientes ad tech da Groone LLC: donos de sites que monetizam com AdSense e Google Ad Manager (GAM). Ele substitui e melhora o Genius, o sistema atual.

- **Foco do MVP:** gestão da empresa e da operação, permissões da equipe, conexão com o GAM.
- **Preço (ideia):** grátis para clientes da rede Groone, pago para os outros.
- **Idiomas:** interface em português, inglês e espanhol. Rotas e código em inglês.
- **Domínios:** `avant.groone.com` (produção) e `staging.avant.groone.com`.
- **Quem desenvolve:** Pedro (dono do produto, escreve em português) e o Claude, de 23/10 até o fim de 2026.

## Modelo de contas

- Painel interno da Groone → **Cliente** → uma **Empresa** por cliente (o cliente cria) → **membros**, cada um com um papel (predefinido ou personalizado).
- Uma pessoa pode estar em várias Empresas; há uma tabela única de usuários.
- O limite de funcionários por cliente é definido no painel interno.
- Entrada só por convite por e-mail (Resend, validade de 1 dia); o login com Google é ligado depois, em Configurações. Sessão por cookie, 2FA por TOTP com códigos de recuperação.
- Permissões: módulo próprio em Python inspirado no `artesaos/defender` do Laravel, com escopo por Empresa. Catálogo de 22 permissões. Sites são atribuídos por membro.
- A Empresa ativa vem da sessão; nenhuma rota tem `company_id` no caminho.
- Chaves de API por pessoa (token `avk_...`, guardado como SHA-256), com limite de taxa no Redis (2/s, rajada de 20).

## GAM

- Uma conta de serviço da Groone para tudo. A conexão é automática quando o cliente aceita o convite MCM; senão, um passo a passo guiado. A conta entra sempre como administradora.
- Ad Manager REST API v1 atrás de um adaptador `gam_client` **somente leitura** (nenhum método de escrita sem revisão do Pedro).
- Descoberta MCM de hora em hora (childPublishers); sites e ad units importados a cada 6 horas.
- Eventos para a tela em tempo real: canal Redis `avant:events:{company_id}`, JSON `{type: "network.updated", data: {network_id}}`, entregue pelo SSE em `/api/v1/events`.

## Arquitetura

- Python 3.12 com uv, FastAPI, Celery (broker RabbitMQ, Redis para resultados, locks, limites e eventos), PostgreSQL para tudo. Front em Vue 3 (SPA), Tailwind e componentes no estilo shadcn-vue (reka-ui).
- Microserviços que dividem um banco. API first.
- **Row Level Security ligado.** A aplicação conecta como `avant_app` (não é dono das tabelas, sem BYPASSRLS); as migrations usam `avant_owner`. A Unit of Work faz `SET app.company_id`. Não mudar isso.
- O `avant-core` segue arquitetura hexagonal pragmática: ports e adapters por módulo (identity, company, access, gam, audit), entidades em dataclass com mapeamento imperativo do SQLAlchemy.

## Repositórios

Todos privados no perfil pessoal `PedroH3nri` no GitHub (fora da organização iGroone).

| Repositório | O que é | Estado em 23/10 |
|---|---|---|
| `avant-core` | Pacote comum: domínio, casos de uso, models, migrations (Alembic), RLS, e-mail. Instalado pela API e pelo worker por tag git. | v0.9.0 (identidade, convites, sessões, 2FA, equipe, auditoria, painel interno, `avant-bootstrap`, Google, GAM, sites, chaves de API) |
| `avant-api` | FastAPI em `/api/v1`, cerca de 80 rotas, rotas internas em `/internal`. | PRs #1 a #13 no `develop`, usa core v0.9.0 |
| `avant-worker` | Celery worker e beat, tarefas `avant.<fila>.<nome>`, filas `default`, `mail` e `gam`. | PRs #1 a #10 no `develop`, usa core v0.9.0 |
| `avant-web` | Painel Vue 3: login, 2FA, convite, equipe e papéis, networks com assistente de conexão, sites e ad units, Minha conta, painel interno `/interno`. | PRs #1 a #7 no `develop` |
| `avant-infra` | Compose local, Postgres, nginx, monitoramento, deploy. | Compose local e deploy nas VMs (`compose/vm`, `scripts/deploy.sh`) no `develop`; ainda não rodou numa VM |

Cada repositório tem um `CLAUDE.md` com as regras dele e um README. Leia os dois antes de mudar algo.

## Onde está o trabalho

**Toda demanda é uma issue com milestone, no repositório certo** (decisão do Pedro, 23/10). Para saber o que fazer: `gh issue list --repo PedroH3nri/<repo> --milestone "<milestone>"`. Um PR fecha a sua issue com `Closes #N`.

| Milestone | Prazo | Conteúdo |
|---|---|---|
| M1 Staging no ar | 06/11 | Deploy nas VMs, pipeline Jenkins e imagens no GHCR, monitoramento, preparação das VMs |
| M2 Segurança e produção | 21/12 | Revisão de segurança, teste de carga, backups testados, E2E, primeiro deploy de produção |
| M3 Piloto | 31/12 | Um cliente real da rede Groone (ainda não escolhido) |
| M4 Métricas do GAM | a definir | Models e sincronização das métricas, motor de consulta, primeira tela de desempenho |
| M5 Personalização e relatórios | a definir | Personalização no estilo HubSpot: dashboards, construtor de relatórios, páginas de relatório no menu, métricas personalizadas (fórmulas), metas, alertas, envios agendados, propriedades personalizadas, visões salvas, tema e marca. Épico: avant-web#22 |
| Pós-MVP | sem data | O que sobrar depois do piloto |

Issues abertas em 23/10 (a lista viva está no GitHub):

- **avant-infra:** #4 pipeline Jenkins e GHCR, #5 monitoramento, #6 tarefas do Pedro, #7 backups, #8 teste de carga, #9 revisão de segurança, #10 deploy de produção, #11 piloto
- **avant-api:** #14 Jenkinsfile; #15 a #26 métricas e personalização
- **avant-worker:** #4 Jenkinsfile, #6 métricas do Celery; #7 a #9 sincronização de métricas, alertas e envios agendados
- **avant-web:** #8 Jenkinsfile, #9 E2E com Playwright; #11 a #21 telas de métricas e personalização; #22 épico da personalização
- **avant-core:** #12 a #23 métricas e personalização

A personalização segue o HubSpot como inspiração (pedido do Pedro, 23/10). Cada funcionalidade tem uma issue por repositório, ligadas entre si: core primeiro, depois api e worker, por fim web.

Fora do escopo por enquanto: port das regras de preço, cobrança, G-Tag, tabela de permissões por papel.

## Como trabalhar nos repositórios

- Branches `feat/...` ou `fix/...` a partir de `develop`; PR para `develop`. `develop` publica em staging, `main` em produção.
- O Claude pode fazer merge dos próprios PRs em `develop` quando o CI passa e não há comentário pendente. `main` e produção ficam com o Pedro.
- Tags do `avant-core` saem pela GitHub Action `release.yml` quando a versão do `pyproject.toml` muda (push de tag direto pode ser bloqueado).
- Antes do PR, Python: `uv run ruff format . && uv run ruff check . && uv run mypy && uv run pytest`. Web: `pnpm lint && pnpm typecheck && pnpm test && pnpm build`.
- Mudança de model que a API usa vira dois PRs: um no core (nova tag) e outro subindo a versão na API e no worker.
- O CI da API e do worker usa o secret `AVANT_CORE_ACCESS` para instalar o core privado.
- Tabela nova com `company_id`: RLS e política na mesma migration, mais teste em `tests/integration/test_rls.py`.
- Migrations precisam funcionar com a versão anterior no ar (blue-green): adicionar coluna num deploy, remover a antiga só no seguinte.
- No `avant-web` não há configuração do Prettier: **não rodar o Prettier** nos arquivos existentes, ele reformata o repositório inteiro.
- No `avant-web`, todo texto em `src/lib/i18n.ts` com PT, EN e ES; tipos da API em `src/lib/types.ts`, iguais aos `schemas.py` da API.
- Caminhos do painel que a API usa e não podem mudar: `/entrar`, `/entrar/2fa`, `/convite/{token}`, `/redefinir-senha/{token}`, `/configuracoes/conta`.
- Nada de segredos no repositório nem na memória. Textos, mensagens de erro e comentários em português.

## Identidade visual

Aprovado: o protótipo navegável no estilo Vercel e o `DESIGN.md` dele (fonte Geist, quase monocromático, primário preto, azul só para links). Tela nova é feita primeiro no protótipo, depois no código. O protótipo do Figma v1 foi rejeitado. O protótipo (React, só referência visual), o `DESIGN.md` e o `PRODUCT.md` ficam em `avant-web/design/`.

## Infraestrutura e operação

- **VM principal** (16 vCPU, 32 GB): produção, que divide a máquina com Genius, Data e MongoDB. Mínimo de 2 instâncias de `api` e de `web`, deploy blue-green.
- **VM pequena** (4 vCPU, 8 GB): Jenkins, Grafana, Prometheus, Loki, staging (1 instância de cada) e backups.
- Imagens no GHCR (`ghcr.io/pedroh3nri/avant-{api,worker,web}`); pipeline no Jenkins.
- TLS no nginx do host; o stack do Avant escuta só em `127.0.0.1`.
- `/api/v1/events` precisa de `proxy_buffering off` em qualquer proxy; `/api/v1/metrics` nunca exposto para a internet.
- Backup com pgBackRest: incremental diário, full semanal, comprimido, retenção de 90 dias, na VM pequena.
- Observabilidade: métricas no Prometheus, logs JSON no Loki com stack traces (sem Sentry), alertas por e-mail.
- Segredos só nas VMs, em `/srv/avant/<ambiente>/`. Variáveis da aplicação: `DATABASE_URL`, `CELERY_BROKER_URL`, `REDIS_URL`, `SESSION_SECRET`, `MFA_ENCRYPTION_KEY`, `RESEND_API_KEY`, `MAIL_FROM`, `APP_BASE_URL`, `GOOGLE_OAUTH_CLIENT_ID/SECRET` (redirect `{APP_BASE_URL}/api/v1/auth/google/callback`), `GAM_SERVICE_ACCOUNT_EMAIL` (api), `GAM_SERVICE_ACCOUNT_FILE` e `GAM_GROONE_NETWORK_CODE` (só no worker da fila gam).

## Tarefas manuais do Pedro

Estão na issue avant-infra#6: DNS e HTTPS dos dois domínios, domínio no Resend, cliente OAuth do Google, chave da conta de serviço do GAM e a conta como administradora, arquivos de segredo nas VMs, login das VMs no GHCR e o `avant-bootstrap` em staging.

Alerta de segurança: o repositório do Genius tem segredos commitados (só Pedro e o sócio tinham acesso). Rotacionar é recomendado.

## Documentos de decisão

Cópias em Markdown em `docs/decisoes/` de cada repositório. São o registro das decisões na época: partes foram superadas pelo que está acima e pelo código (por exemplo, o monorepo virou cinco repositórios, o Caddy virou nginx e o cabeçalho `X-Company-Id` virou a Empresa da sessão). Os originais ficaram na conta antiga do claude.ai:

- Requisitos: https://claude.ai/artifact/Xufx2Nkwr4DELmjrApJTGR
- Arquitetura: https://claude.ai/artifact/7oqA6vBK2jQ1Ab4axWWFBL
- Models do MVP (18 models): https://claude.ai/artifact/ViYx1Num6BuctgtgW34Cae
- Conexão com o GAM: https://claude.ai/artifact/4awpwUxBW9VMQoeFN5pvPp
- Fluxos de login e convite: https://claude.ai/artifact/ErKHgj8puoFooDwBK8JB4e
- Endpoints da API: https://claude.ai/artifact/YWMmSvEW9xbVuG5gnbvd5Y
- Repositórios e plano do MVP: https://claude.ai/artifact/9mfxsywc68VEJqeYKDWFPT
- Protótipo navegável: https://claude.ai/artifact/MJJHKXxGN2GA8tpakMnemf

## Skills e ferramentas

- `docs/skills/` tem todas as skills que o repositório usa: as do Avant (`avant-*`), as do [superpowers](https://github.com/obra/superpowers) e a do [graphify](https://github.com/Graphify-Labs/graphify). O `docs/skills/README.md` diz quando usar cada uma. `.claude/skills` aponta para essa pasta.
- O `.claude/settings.json` carrega a `using-superpowers` no começo de cada sessão.
- graphify: o grafo do código está versionado em `graphify-out/` de cada repositório (`GRAPH_REPORT.md` para ler; `graph.json` para `graphify query "..."`, `graphify path "A" "B"` e `graphify explain "X"`). Consulte antes de sair lendo arquivo por arquivo. Depois de mudar código, rode `graphify update .` (instale com `uv tool install graphifyy`; é local e sem LLM) e commite o grafo junto. O `.graphifyignore` deixa as skills de terceiros de fora.

## Dicas de ambiente para o agente

- `gh pr create` pode falhar (GraphQL bloqueado pelo proxy): abrir PR com `gh api repos/PedroH3nri/<repo>/pulls -f base=develop -f head=<branch> ...`.
- Clones rasos: `git fetch origin develop:refs/remotes/origin/develop`.
- Não há Postgres local na sessão; os testes de integração da API rodam no CI.
