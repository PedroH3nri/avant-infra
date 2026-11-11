# Graph Report - avant-infra  (2026-11-11)

## Corpus Check
- 34 files · ~29,268 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 13 file(s) not represented in the graph (top: (none) 4, .example 3, .env 2)

## Summary
- 632 nodes · 757 edges · 55 communities (46 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c42d5e47`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- api
- Avant: models do MVP
- postgres
- services
- nginx
- api-green
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
- jenkins
- scrape_configs
- Rodar o Avant em modo de desenvolvimento
- redis
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
- scheduler
- python-checks.sh
- remote-deploy.sh
- services
- secrets
- Avant: grupos na Empresa e imagem da Empresa
- rabbitmq
- x-api
- x-web
- healthcheck
- nginx
- redis
- web
- x-app

## God Nodes (most connected - your core abstractions)
1. `options` - 19 edges
2. `driver` - 17 edges
3. `services` - 14 edges
4. `api-blue` - 14 edges
5. `api-green` - 14 edges
6. `Groone Avant: contexto do projeto` - 14 edges
7. `Rodar o Avant em modo de desenvolvimento` - 14 edges
8. `postgres` - 13 edges
9. `worker` - 13 edges
10. `worker-gam` - 13 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (55 total, 9 thin omitted)

### Community 0 - "api"
Cohesion: 0.08
Nodes (29): build, depends_on, env_file, environment, ports, profiles, postgres, rabbitmq (+21 more)

### Community 1 - "Avant: models do MVP"
Cohesion: 0.07
Nodes (26): Acesso, AdUnit, ApiKey, AuditLog, Avant: models do MVP, Company, Decisões de Pedro (22/10/2026), Empresa e equipe (+18 more)

### Community 2 - "postgres"
Cohesion: 0.22
Nodes (9): POSTGRES_DB, POSTGRES_PASSWORD_FILE, POSTGRES_USER, environment, image, ports, secrets, volumes (+1 more)

### Community 3 - "services"
Cohesion: 0.05
Nodes (41): environment, name, environment, file, name, networks, avant, environment (+33 more)

### Community 4 - "nginx"
Cohesion: 0.09
Nodes (27): RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval, retries, test, cpus, healthcheck, image (+19 more)

### Community 5 - "api-green"
Cohesion: 0.13
Nodes (24): depends_on, cpus, depends_on, env_file, image, mem_limit, networks, profiles (+16 more)

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
Nodes (8): web-blue, cpus, deploy, image, mem_limit, networks, profiles, restart

### Community 13 - "Requisitos do novo SaaS AdTech Groone"
Cohesion: 0.17
Nodes (11): Conta e equipe, Escopo herdado do Genius, Integrações e onboarding no Google Ad Manager, Modelo de cobrança, MVP, Opções de nome, Perguntas em aberto, Problemas a resolver (+3 more)

### Community 14 - "Avant: fluxos de login e convite"
Cohesion: 0.17
Nodes (11): 2FA, Avant: fluxos de login e convite, Com Google, Com senha, Convite e primeiro acesso, Decisões de Pedro (23/10/2026), Endpoints de autenticação, Escolha da Empresa ativa (+3 more)

### Community 15 - "worker-gam"
Cohesion: 0.15
Nodes (13): source, target, worker-gam, command, cpus, env_file, image, logging (+5 more)

### Community 16 - "migrate"
Cohesion: 0.18
Nodes (11): DATABASE_MIGRATIONS_URL, command, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 17 - "Avant: conexão com o GAM"
Cohesion: 0.20
Nodes (9): Avant: conexão com o GAM, Caminho conta de serviço, Caminho MCM, Decisões de Pedro (23/10/2026), Erros e estados, Fontes, Importação, Resumo (+1 more)

### Community 18 - "libraries"
Cohesion: 0.09
Nodes (22): credentials, file, string, system, usernamePassword, credentials, libraries, jobs (+14 more)

### Community 19 - "Avant: repositório e plano do MVP"
Cohesion: 0.22
Nodes (8): Avant: repositório e plano do MVP, Decisões de Pedro (23/10/2026), Estrutura de pastas, Pipeline, Plano até 31/12, Primeira semana (23/10 a 02/11), Resumo, Serviços e ferramentas

### Community 20 - "environment"
Cohesion: 0.05
Nodes (39): file, file, file, AVANT_PRODUCTION_HOST, AVANT_STAGING_HOST, CASC_JENKINS_CONFIG, GITHUB_USER, JAVA_OPTS (+31 more)

### Community 21 - "jenkins"
Cohesion: 0.11
Nodes (18): loggedInUsersCanDoAnything, key, value, env, envVars, jenkins, authorizationStrategy, globalNodeProperties (+10 more)

### Community 22 - "scrape_configs"
Cohesion: 0.25
Nodes (7): global, scrape_interval, scrape_configs, job_name, metrics_path, static_configs, targets

### Community 23 - "Rodar o Avant em modo de desenvolvimento"
Cohesion: 0.06
Nodes (32): 10. Testes, 11. Mudando o avant-core junto com a API ou o worker, 12. Problemas comuns, 1. O que instalar, 2. Clonar os cinco repositórios lado a lado, 3. Subir Postgres, RabbitMQ e Redis, 4. Variáveis da aplicação, 5. Migrations e primeiro usuário (+24 more)

### Community 24 - "redis"
Cohesion: 0.18
Nodes (11): REDISCLI_AUTH, command, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 25 - "celery-exporter"
Cohesion: 0.18
Nodes (11): cpus, depends_on, environment, image, logging, mem_limit, networks, restart (+3 more)

### Community 26 - "options"
Cohesion: 0.24
Nodes (14): logging, logging, driver, options, max-file, max-size, logging, logging (+6 more)

### Community 27 - "api-blue"
Cohesion: 0.20
Nodes (10): cpus, env_file, image, mem_limit, networks, profiles, restart, stop_grace_period (+2 more)

### Community 28 - "updates"
Cohesion: 0.13
Nodes (14): imagens, dependency-name, update-types, patterns, interval, updates, directories, directory (+6 more)

### Community 29 - "web-green"
Cohesion: 0.29
Nodes (7): web-green, cpus, image, mem_limit, networks, profiles, restart

### Community 33 - "node-checks.sh"
Cohesion: 0.33
Nodes (5): COREPACK_ENABLE_DOWNLOAD_PROMPT, COREPACK_HOME, HOME, npm_config_store_dir, node-checks.sh script

### Community 34 - "replicas"
Cohesion: 0.33
Nodes (6): deploy, deploy, replicas, deploy, deploy, deploy

### Community 35 - "scheduler"
Cohesion: 0.22
Nodes (9): command, cpus, env_file, image, mem_limit, networks, restart, stop_grace_period (+1 more)

### Community 36 - "python-checks.sh"
Cohesion: 0.40
Nodes (4): HOME, python-checks.sh script, UV_CACHE_DIR, UV_PYTHON_DOWNLOADS

### Community 37 - "remote-deploy.sh"
Cohesion: 0.83
Nodes (3): die(), main(), remote-deploy.sh script

### Community 44 - "services"
Cohesion: 0.25
Nodes (7): name, services, volumes, postgres-data, x-app-env, CELERY_BROKER_URL, REDIS_URL

### Community 45 - "secrets"
Cohesion: 0.29
Nodes (7): environment, environment, environment, secrets, avant-app-password, avant-owner-password, postgres-password

### Community 46 - "Avant: grupos na Empresa e imagem da Empresa"
Cohesion: 0.20
Nodes (9): Avant: grupos na Empresa e imagem da Empresa, Decisões do Pedro (26/10), Herança de comissão e meta, Imagem da Empresa, Issues, Modelo de dados, Regras, Resumo (+1 more)

### Community 47 - "rabbitmq"
Cohesion: 0.33
Nodes (6): RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, environment, image, ports, rabbitmq

### Community 48 - "x-api"
Cohesion: 0.25
Nodes (8): x-api, cpus, env_file, mem_limit, networks, restart, stop_grace_period, volumes

### Community 49 - "x-web"
Cohesion: 0.33
Nodes (6): x-web, cpus, deploy, mem_limit, networks, restart

### Community 50 - "healthcheck"
Cohesion: 0.60
Nodes (6): interval, retries, test, healthcheck, healthcheck, healthcheck

### Community 51 - "nginx"
Cohesion: 0.33
Nodes (6): depends_on, image, ports, profiles, volumes, nginx

### Community 52 - "redis"
Cohesion: 0.50
Nodes (4): command, image, ports, redis

### Community 53 - "web"
Cohesion: 0.50
Nodes (4): web, build, depends_on, profiles

### Community 54 - "x-app"
Cohesion: 0.50
Nodes (4): x-app, env_file, networks, restart

## Knowledge Gaps
- **7 isolated node(s):** `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT`, `npm_config_store_dir`, `HOME` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 406 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `services` to `scheduler`, `nginx`, `api-green`, `postgres`, `web-blue`, `worker-gam`, `migrate`, `redis`, `celery-exporter`, `api-blue`, `web-green`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **What connects `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `api` be split into smaller, more focused modules?**
  _Cohesion score 0.08374384236453201 - nodes in this community are weakly interconnected._
- **Why does `postgres` connect `postgres` to `options`, `services`, `nginx`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Should `Avant: models do MVP` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Why does `worker-gam` connect `worker-gam` to `APP_BASE_URL`, `services`, `api-green`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.047619047619047616 - nodes in this community are weakly interconnected._