# Graph Report - avant-infra  (2026-11-09)

## Corpus Check
- 34 files · ~27,279 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: (none) 4, .example 3, .env 2)

## Summary
- 619 nodes · 740 edges · 51 communities (42 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a05f155c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- services
- Avant: models do MVP
- postgres
- services
- redis
- scheduler
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
- jenkins
- Avant: repositório e plano do MVP
- environment
- api-green
- scrape_configs
- Rodar o Avant em modo de desenvolvimento
- secrets
- celery-exporter
- options
- api-blue
- updates
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
- rabbitmq
- Avant: grupos na Empresa e imagem da Empresa
- secrets
- x-api
- x-web
- x-env

## God Nodes (most connected - your core abstractions)
1. `options` - 19 edges
2. `driver` - 17 edges
3. `services` - 14 edges
4. `Groone Avant: contexto do projeto` - 14 edges
5. `Rodar o Avant em modo de desenvolvimento` - 14 edges
6. `postgres` - 13 edges
7. `api-blue` - 13 edges
8. `api-green` - 13 edges
9. `worker-gam` - 13 edges
10. `scheduler` - 13 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (51 total, 9 thin omitted)

### Community 0 - "services"
Cohesion: 0.05
Nodes (45): build, depends_on, env_file, ports, profiles, environment, environment, postgres (+37 more)

### Community 1 - "Avant: models do MVP"
Cohesion: 0.07
Nodes (26): Acesso, AdUnit, ApiKey, AuditLog, Avant: models do MVP, Company, Decisões de Pedro (22/10/2026), Empresa e equipe (+18 more)

### Community 2 - "postgres"
Cohesion: 0.09
Nodes (25): POSTGRES_DB, POSTGRES_PASSWORD_FILE, POSTGRES_USER, RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval, retries, test (+17 more)

### Community 3 - "services"
Cohesion: 0.20
Nodes (9): name, name, networks, avant, services, volumes, postgres-data, rabbitmq-data (+1 more)

### Community 4 - "redis"
Cohesion: 0.09
Nodes (27): REDISCLI_AUTH, interval, retries, test, cpus, healthcheck, image, logging (+19 more)

### Community 5 - "scheduler"
Cohesion: 0.13
Nodes (24): depends_on, depends_on, postgres, rabbitmq, redis, depends_on, condition, condition (+16 more)

### Community 6 - "Groone Avant: contexto do projeto"
Cohesion: 0.12
Nodes (15): Arquitetura, Como trabalhar nos repositórios, Dicas de ambiente para o agente, Documentos de decisão, GAM, Groone Avant: contexto do projeto, Identidade visual, Infraestrutura e operação (+7 more)

### Community 7 - "Avant: endpoints da API do MVP"
Cohesion: 0.12
Nodes (16): API first e chaves de API, Atribuição de sites, Avant: endpoints da API do MVP, Catálogo de permissões, Convenções, Convites, Decisões de Pedro (23/10/2026), Empresa (+8 more)

### Community 8 - "deploy.sh"
Cohesion: 0.38
Nodes (15): compose(), deploy_color(), die(), ensure_base(), get(), log(), other(), point_nginx() (+7 more)

### Community 9 - "APP_BASE_URL"
Cohesion: 0.45
Nodes (14): environment, environment, APP_BASE_URL, AVANT_ENV, CELERY_BROKER_URL, DATABASE_URL, GAM_SERVICE_ACCOUNT_FILE, REDIS_URL (+6 more)

### Community 10 - "postgres"
Cohesion: 0.14
Nodes (14): POSTGRES_DB, POSTGRES_PASSWORD_FILE, POSTGRES_USER, command, cpus, environment, image, mem_limit (+6 more)

### Community 11 - "Arquitetura do MVP do Avant"
Cohesion: 0.14
Nodes (13): Ambientes, deploy e backup, Arquitetura do MVP do Avant, Controle de acesso no estilo do Defender, Decisões e perguntas em aberto, Endpoints da API REST, Estrutura do repositório, Fluxos, Isolamento, autenticação e permissões (+5 more)

### Community 12 - "web-blue"
Cohesion: 0.25
Nodes (8): web-blue, cpus, image, logging, mem_limit, networks, profiles, restart

### Community 13 - "Requisitos do novo SaaS AdTech Groone"
Cohesion: 0.17
Nodes (11): Conta e equipe, Escopo herdado do Genius, Integrações e onboarding no Google Ad Manager, Modelo de cobrança, MVP, Opções de nome, Perguntas em aberto, Problemas a resolver (+3 more)

### Community 14 - "Avant: fluxos de login e convite"
Cohesion: 0.17
Nodes (11): 2FA, Avant: fluxos de login e convite, Com Google, Com senha, Convite e primeiro acesso, Decisões de Pedro (23/10/2026), Endpoints de autenticação, Escolha da Empresa ativa (+3 more)

### Community 15 - "worker-gam"
Cohesion: 0.17
Nodes (12): source, target, worker-gam, command, cpus, env_file, image, mem_limit (+4 more)

### Community 16 - "migrate"
Cohesion: 0.18
Nodes (11): DATABASE_MIGRATIONS_URL, command, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 17 - "Avant: conexão com o GAM"
Cohesion: 0.20
Nodes (9): Avant: conexão com o GAM, Caminho conta de serviço, Caminho MCM, Decisões de Pedro (23/10/2026), Erros e estados, Fontes, Importação, Resumo (+1 more)

### Community 18 - "jenkins"
Cohesion: 0.05
Nodes (40): loggedInUsersCanDoAnything, credentials, file, string, system, usernamePassword, credentials, key (+32 more)

### Community 19 - "Avant: repositório e plano do MVP"
Cohesion: 0.22
Nodes (8): Avant: repositório e plano do MVP, Decisões de Pedro (23/10/2026), Estrutura de pastas, Pipeline, Plano até 31/12, Primeira semana (23/10 a 02/11), Resumo, Serviços e ferramentas

### Community 20 - "environment"
Cohesion: 0.09
Nodes (22): AVANT_PRODUCTION_HOST, AVANT_STAGING_HOST, CASC_JENKINS_CONFIG, GITHUB_USER, JAVA_OPTS, JENKINS_ADMIN_USER, JENKINS_HOME, JENKINS_URL (+14 more)

### Community 21 - "api-green"
Cohesion: 0.22
Nodes (9): cpus, env_file, image, mem_limit, networks, profiles, restart, stop_grace_period (+1 more)

### Community 22 - "scrape_configs"
Cohesion: 0.25
Nodes (7): global, scrape_interval, scrape_configs, job_name, metrics_path, static_configs, targets

### Community 23 - "Rodar o Avant em modo de desenvolvimento"
Cohesion: 0.06
Nodes (31): 10. Testes, 11. Mudando o avant-core junto com a API ou o worker, 12. Problemas comuns, 1. O que instalar, 2. Clonar os cinco repositórios lado a lado, 3. Subir Postgres, RabbitMQ e Redis, 4. Variáveis da aplicação, 5. Migrations e primeiro usuário (+23 more)

### Community 24 - "secrets"
Cohesion: 0.11
Nodes (17): file, file, file, file, file, file, file, name (+9 more)

### Community 25 - "celery-exporter"
Cohesion: 0.18
Nodes (11): cpus, depends_on, environment, image, logging, mem_limit, networks, restart (+3 more)

### Community 26 - "options"
Cohesion: 0.21
Nodes (13): logging, logging, driver, options, max-file, max-size, logging, logging (+5 more)

### Community 27 - "api-blue"
Cohesion: 0.22
Nodes (9): cpus, env_file, image, mem_limit, networks, profiles, restart, stop_grace_period (+1 more)

### Community 28 - "updates"
Cohesion: 0.13
Nodes (14): imagens, dependency-name, update-types, patterns, interval, updates, directories, directory (+6 more)

### Community 29 - "web-green"
Cohesion: 0.25
Nodes (8): web-green, cpus, image, logging, mem_limit, networks, profiles, restart

### Community 33 - "node-checks.sh"
Cohesion: 0.33
Nodes (5): COREPACK_ENABLE_DOWNLOAD_PROMPT, COREPACK_HOME, HOME, npm_config_store_dir, node-checks.sh script

### Community 34 - "replicas"
Cohesion: 0.29
Nodes (7): deploy, deploy, replicas, deploy, deploy, deploy, deploy

### Community 35 - "worker"
Cohesion: 0.20
Nodes (10): worker, command, cpus, env_file, image, logging, mem_limit, networks (+2 more)

### Community 36 - "python-checks.sh"
Cohesion: 0.40
Nodes (4): HOME, python-checks.sh script, UV_CACHE_DIR, UV_PYTHON_DOWNLOADS

### Community 37 - "remote-deploy.sh"
Cohesion: 0.83
Nodes (3): die(), main(), remote-deploy.sh script

### Community 44 - "x-worker"
Cohesion: 0.29
Nodes (7): x-worker, env_file, image, logging, networks, restart, stop_grace_period

### Community 45 - "rabbitmq"
Cohesion: 0.18
Nodes (11): RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 46 - "Avant: grupos na Empresa e imagem da Empresa"
Cohesion: 0.20
Nodes (9): Avant: grupos na Empresa e imagem da Empresa, Decisões do Pedro (26/10), Herança de comissão e meta, Imagem da Empresa, Issues, Modelo de dados, Regras, Resumo (+1 more)

### Community 47 - "secrets"
Cohesion: 0.22
Nodes (9): environment, environment, file, environment, secrets, avant-app-password, avant-owner-password, gam-service-account (+1 more)

### Community 48 - "x-api"
Cohesion: 0.25
Nodes (8): x-api, cpus, env_file, logging, mem_limit, networks, restart, stop_grace_period

### Community 49 - "x-web"
Cohesion: 0.29
Nodes (7): x-web, cpus, deploy, logging, mem_limit, networks, restart

### Community 50 - "x-env"
Cohesion: 0.33
Nodes (6): x-env, APP_BASE_URL, AVANT_ENV, CELERY_BROKER_URL, DATABASE_URL, REDIS_URL

## Knowledge Gaps
- **7 isolated node(s):** `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT`, `npm_config_store_dir`, `HOME` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 399 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `services` to `worker`, `redis`, `scheduler`, `postgres`, `web-blue`, `rabbitmq`, `worker-gam`, `migrate`, `api-green`, `celery-exporter`, `api-blue`, `web-green`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **What connects `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.04734299516908213 - nodes in this community are weakly interconnected._
- **Why does `postgres` connect `postgres` to `options`, `services`, `redis`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Should `Avant: models do MVP` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Why does `worker-gam` connect `worker-gam` to `APP_BASE_URL`, `options`, `services`, `scheduler`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Should `postgres` be split into smaller, more focused modules?**
  _Cohesion score 0.09333333333333334 - nodes in this community are weakly interconnected._