# Graph Report - avant-infra  (2026-10-26)

## Corpus Check
- 32 files · ~24,114 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: (none) 4, .example 3, .env 2)

## Summary
- 544 nodes · 667 edges · 46 communities (37 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d08c1ffa`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- services
- Avant: models do MVP
- environment
- services
- nginx
- postgres
- Groone Avant: contexto do projeto
- Avant: endpoints da API do MVP
- deploy.sh
- APP_BASE_URL
- postgres
- Arquitetura do MVP do Avant
- web-blue
- Requisitos do novo SaaS AdTech Groone
- Avant: fluxos de login e convite
- worker-gam
- migrate
- Avant: conexão com o GAM
- libraries
- Avant: repositório e plano do MVP
- environment
- api-green
- scrape_configs
- Rodar o Avant em modo de desenvolvimento
- jenkins
- celery-exporter
- options
- api-blue
- scheduler
- web-green
- avant-infra
- session-start.sh
- 01-roles.sh
- node-checks.sh
- replicas
- worker
- python-checks.sh
- remote-deploy.sh
- x-worker
- x-app

## God Nodes (most connected - your core abstractions)
1. `options` - 19 edges
2. `driver` - 17 edges
3. `services` - 14 edges
4. `Groone Avant: contexto do projeto` - 14 edges
5. `Rodar o Avant em modo de desenvolvimento` - 14 edges
6. `deploy.sh script` - 12 edges
7. `Arquitetura do MVP do Avant` - 12 edges
8. `api-blue` - 11 edges
9. `api-green` - 11 edges
10. `worker-gam` - 11 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (46 total, 9 thin omitted)

### Community 0 - "services"
Cohesion: 0.06
Nodes (38): build, depends_on, env_file, ports, profiles, postgres, rabbitmq, redis (+30 more)

### Community 1 - "Avant: models do MVP"
Cohesion: 0.07
Nodes (26): Acesso, AdUnit, ApiKey, AuditLog, Avant: models do MVP, Company, Decisões de Pedro (22/10/2026), Empresa e equipe (+18 more)

### Community 2 - "environment"
Cohesion: 0.09
Nodes (26): AVANT_APP_PASSWORD, AVANT_OWNER_PASSWORD, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval (+18 more)

### Community 3 - "services"
Cohesion: 0.11
Nodes (17): name, file, name, networks, avant, secrets, gam-service-account, volumes (+9 more)

### Community 4 - "nginx"
Cohesion: 0.08
Nodes (30): RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval, retries, test, healthcheck, image, logging (+22 more)

### Community 5 - "postgres"
Cohesion: 0.18
Nodes (19): depends_on, depends_on, postgres, rabbitmq, redis, condition, condition, condition (+11 more)

### Community 6 - "Groone Avant: contexto do projeto"
Cohesion: 0.12
Nodes (15): Arquitetura, Como trabalhar nos repositórios, Dicas de ambiente para o agente, Documentos de decisão, GAM, Groone Avant: contexto do projeto, Identidade visual, Infraestrutura e operação (+7 more)

### Community 7 - "Avant: endpoints da API do MVP"
Cohesion: 0.12
Nodes (16): API first e chaves de API, Atribuição de sites, Avant: endpoints da API do MVP, Catálogo de permissões, Convenções, Convites, Decisões de Pedro (23/10/2026), Empresa (+8 more)

### Community 8 - "deploy.sh"
Cohesion: 0.42
Nodes (15): compose(), deploy_color(), die(), ensure_base(), get(), log(), other(), point_nginx() (+7 more)

### Community 9 - "APP_BASE_URL"
Cohesion: 0.45
Nodes (14): environment, environment, APP_BASE_URL, AVANT_ENV, CELERY_BROKER_URL, DATABASE_URL, GAM_SERVICE_ACCOUNT_FILE, REDIS_URL (+6 more)

### Community 10 - "postgres"
Cohesion: 0.14
Nodes (14): AVANT_APP_PASSWORD, AVANT_OWNER_PASSWORD, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, command, environment, image (+6 more)

### Community 11 - "Arquitetura do MVP do Avant"
Cohesion: 0.14
Nodes (13): Ambientes, deploy e backup, Arquitetura do MVP do Avant, Controle de acesso no estilo do Defender, Decisões e perguntas em aberto, Endpoints da API REST, Estrutura do repositório, Fluxos, Isolamento, autenticação e permissões (+5 more)

### Community 12 - "web-blue"
Cohesion: 0.33
Nodes (6): services, web-blue, image, networks, profiles, restart

### Community 13 - "Requisitos do novo SaaS AdTech Groone"
Cohesion: 0.17
Nodes (11): Conta e equipe, Escopo herdado do Genius, Integrações e onboarding no Google Ad Manager, Modelo de cobrança, MVP, Opções de nome, Perguntas em aberto, Problemas a resolver (+3 more)

### Community 14 - "Avant: fluxos de login e convite"
Cohesion: 0.17
Nodes (11): 2FA, Avant: fluxos de login e convite, Com Google, Com senha, Convite e primeiro acesso, Decisões de Pedro (23/10/2026), Endpoints de autenticação, Escolha da Empresa ativa (+3 more)

### Community 15 - "worker-gam"
Cohesion: 0.18
Nodes (11): source, target, worker-gam, command, env_file, image, logging, networks (+3 more)

### Community 16 - "migrate"
Cohesion: 0.20
Nodes (10): DATABASE_MIGRATIONS_URL, command, depends_on, environment, image, logging, networks, profiles (+2 more)

### Community 17 - "Avant: conexão com o GAM"
Cohesion: 0.20
Nodes (9): Avant: conexão com o GAM, Caminho conta de serviço, Caminho MCM, Decisões de Pedro (23/10/2026), Erros e estados, Fontes, Importação, Resumo (+1 more)

### Community 18 - "libraries"
Cohesion: 0.08
Nodes (23): credentials, basicSSHUserPrivateKey, file, string, system, usernamePassword, credentials, libraries (+15 more)

### Community 19 - "Avant: repositório e plano do MVP"
Cohesion: 0.22
Nodes (8): Avant: repositório e plano do MVP, Decisões de Pedro (23/10/2026), Estrutura de pastas, Pipeline, Plano até 31/12, Primeira semana (23/10 a 02/11), Resumo, Serviços e ferramentas

### Community 20 - "environment"
Cohesion: 0.05
Nodes (37): file, file, AVANT_PRODUCTION_HOST, AVANT_STAGING_HOST, CASC_JENKINS_CONFIG, GITHUB_USER, JAVA_OPTS, JENKINS_ADMIN_USER (+29 more)

### Community 21 - "api-green"
Cohesion: 0.25
Nodes (8): env_file, image, logging, networks, profiles, restart, stop_grace_period, api-green

### Community 22 - "scrape_configs"
Cohesion: 0.25
Nodes (7): global, scrape_interval, scrape_configs, job_name, metrics_path, static_configs, targets

### Community 23 - "Rodar o Avant em modo de desenvolvimento"
Cohesion: 0.07
Nodes (26): 10. Testes, 11. Mudando o avant-core junto com a API ou o worker, 12. Problemas comuns, 1. O que instalar, 2. Clonar os cinco repositórios lado a lado, 3. Subir Postgres, RabbitMQ e Redis, 4. Variáveis da aplicação, 5. Migrations e primeiro usuário (+18 more)

### Community 24 - "jenkins"
Cohesion: 0.11
Nodes (18): loggedInUsersCanDoAnything, key, value, env, envVars, jenkins, authorizationStrategy, globalNodeProperties (+10 more)

### Community 25 - "celery-exporter"
Cohesion: 0.22
Nodes (9): depends_on, environment, image, logging, networks, restart, CE_BROKER_URL, CE_PORT (+1 more)

### Community 26 - "options"
Cohesion: 0.21
Nodes (12): logging, driver, options, max-file, max-size, logging, logging, x-web (+4 more)

### Community 27 - "api-blue"
Cohesion: 0.25
Nodes (8): deploy, env_file, image, networks, profiles, restart, stop_grace_period, api-blue

### Community 28 - "scheduler"
Cohesion: 0.25
Nodes (8): command, env_file, image, logging, networks, restart, stop_grace_period, scheduler

### Community 29 - "web-green"
Cohesion: 0.33
Nodes (6): web-green, image, logging, networks, profiles, restart

### Community 33 - "node-checks.sh"
Cohesion: 0.33
Nodes (5): COREPACK_ENABLE_DOWNLOAD_PROMPT, COREPACK_HOME, HOME, npm_config_store_dir, node-checks.sh script

### Community 34 - "replicas"
Cohesion: 0.33
Nodes (6): deploy, replicas, deploy, deploy, deploy, deploy

### Community 35 - "worker"
Cohesion: 0.29
Nodes (7): worker, command, env_file, image, networks, restart, stop_grace_period

### Community 36 - "python-checks.sh"
Cohesion: 0.40
Nodes (4): HOME, python-checks.sh script, UV_CACHE_DIR, UV_PYTHON_DOWNLOADS

### Community 37 - "remote-deploy.sh"
Cohesion: 0.83
Nodes (3): die(), main(), remote-deploy.sh script

### Community 44 - "x-worker"
Cohesion: 0.29
Nodes (7): x-worker, env_file, image, logging, networks, restart, stop_grace_period

### Community 45 - "x-app"
Cohesion: 0.40
Nodes (5): x-app, env_file, logging, networks, restart

## Knowledge Gaps
- **7 isolated node(s):** `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT`, `npm_config_store_dir`, `HOME` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 341 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `web-blue` to `services`, `nginx`, `worker`, `postgres`, `worker-gam`, `migrate`, `api-green`, `celery-exporter`, `api-blue`, `scheduler`, `web-green`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **What connects `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.05668016194331984 - nodes in this community are weakly interconnected._
- **Why does `postgres` connect `postgres` to `web-blue`, `nginx`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `Avant: models do MVP` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Why does `worker-gam` connect `worker-gam` to `APP_BASE_URL`, `web-blue`, `postgres`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `environment` be split into smaller, more focused modules?**
  _Cohesion score 0.08923076923076922 - nodes in this community are weakly interconnected._