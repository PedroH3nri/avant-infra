# Graph Report - avant-infra  (2026-11-12)

## Corpus Check
- 38 files · ~33,726 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: (none) 4, .example 3, .env 2)

## Summary
- 705 nodes · 861 edges · 54 communities (44 shown, 10 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2e6b5ce4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- api
- Avant: models do MVP
- postgres
- api-blue
- avant
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
- redis
- scrape_configs
- Rodar o Avant em modo de desenvolvimento
- redis
- celery-exporter
- options
- x-worker
- updates
- web-green
- avant-infra
- session-start.sh
- 01-roles.sh
- node-checks.sh
- x-api
- conferir-segredos.sh
- python-checks.sh
- remote-deploy.sh
- conferir-subnet.sh
- x-app
- Avant: grupos na Empresa e imagem da Empresa
- x-env
- x-web
- nginx
- firewall-saida.sh
- services
- secrets

## God Nodes (most connected - your core abstractions)
1. `options` - 19 edges
2. `driver` - 17 edges
3. `api-blue` - 15 edges
4. `api-green` - 15 edges
5. `Rodar o Avant em modo de desenvolvimento` - 15 edges
6. `services` - 14 edges
7. `worker` - 14 edges
8. `worker-gam` - 14 edges
9. `scheduler` - 14 edges
10. `Groone Avant: contexto do projeto` - 14 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (54 total, 10 thin omitted)

### Community 0 - "api"
Cohesion: 0.08
Nodes (35): build, depends_on, env_file, environment, ports, profiles, context, secrets (+27 more)

### Community 1 - "Avant: models do MVP"
Cohesion: 0.07
Nodes (26): Acesso, AdUnit, ApiKey, AuditLog, Avant: models do MVP, Company, Decisões de Pedro (22/10/2026), Empresa e equipe (+18 more)

### Community 2 - "postgres"
Cohesion: 0.07
Nodes (34): POSTGRES_DB, POSTGRES_PASSWORD_FILE, POSTGRES_USER, RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval, retries, test (+26 more)

### Community 3 - "api-blue"
Cohesion: 0.05
Nodes (39): cap_drop, cpus, deploy, env_file, image, mem_limit, networks, profiles (+31 more)

### Community 4 - "avant"
Cohesion: 0.17
Nodes (12): driver_opts, ipam, ipv4_address, name, gateway, ip_range, subnet, com.docker.network.bridge.name (+4 more)

### Community 5 - "api-green"
Cohesion: 0.12
Nodes (25): depends_on, depends_on, postgres, rabbitmq, redis, depends_on, condition, condition (+17 more)

### Community 6 - "Groone Avant: contexto do projeto"
Cohesion: 0.12
Nodes (15): Arquitetura, Como trabalhar nos repositórios, Dicas de ambiente para o agente, Documentos de decisão, GAM, Groone Avant: contexto do projeto, Identidade visual, Infraestrutura e operação (+7 more)

### Community 7 - "Avant: endpoints da API do MVP"
Cohesion: 0.12
Nodes (16): API first e chaves de API, Atribuição de sites, Avant: endpoints da API do MVP, Catálogo de permissões, Convenções, Convites, Decisões de Pedro (23/10/2026), Empresa (+8 more)

### Community 8 - "deploy.sh"
Cohesion: 0.39
Nodes (15): compose(), deploy_color(), die(), ensure_base(), get(), log(), other(), point_nginx() (+7 more)

### Community 9 - "APP_BASE_URL"
Cohesion: 0.42
Nodes (15): environment, environment, APP_BASE_URL, AVANT_ENV, CELERY_BROKER_URL, DATABASE_URL, FORWARDED_ALLOW_IPS, GAM_SERVICE_ACCOUNT_FILE (+7 more)

### Community 10 - "postgres"
Cohesion: 0.13
Nodes (15): POSTGRES_DB, POSTGRES_PASSWORD_FILE, POSTGRES_USER, command, cpus, environment, image, logging (+7 more)

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
Cohesion: 0.14
Nodes (14): source, target, worker-gam, cap_drop, command, cpus, env_file, image (+6 more)

### Community 16 - "migrate"
Cohesion: 0.18
Nodes (11): DATABASE_MIGRATIONS_URL, command, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 17 - "Avant: conexão com o GAM"
Cohesion: 0.20
Nodes (9): Avant: conexão com o GAM, Caminho conta de serviço, Caminho MCM, Decisões de Pedro (23/10/2026), Erros e estados, Fontes, Importação, Resumo (+1 more)

### Community 18 - "libraries"
Cohesion: 0.05
Nodes (40): loggedInUsersCanDoAnything, credentials, file, string, system, usernamePassword, credentials, key (+32 more)

### Community 19 - "Avant: repositório e plano do MVP"
Cohesion: 0.22
Nodes (8): Avant: repositório e plano do MVP, Decisões de Pedro (23/10/2026), Estrutura de pastas, Pipeline, Plano até 31/12, Primeira semana (23/10 a 02/11), Resumo, Serviços e ferramentas

### Community 20 - "environment"
Cohesion: 0.05
Nodes (39): file, file, file, AVANT_PRODUCTION_HOST, AVANT_STAGING_HOST, CASC_JENKINS_CONFIG, GITHUB_USER, JAVA_OPTS (+31 more)

### Community 21 - "redis"
Cohesion: 0.09
Nodes (28): AVANT_GATEWAY_IP, RABBITMQ_DEFAULT_PASS, RABBITMQ_DEFAULT_USER, interval, retries, test, cpus, environment (+20 more)

### Community 22 - "scrape_configs"
Cohesion: 0.25
Nodes (7): global, scrape_interval, scrape_configs, job_name, metrics_path, static_configs, targets

### Community 23 - "Rodar o Avant em modo de desenvolvimento"
Cohesion: 0.05
Nodes (35): 10. Testes, 11. Mudando o avant-core junto com a API ou o worker, 12. Problemas comuns, 1. O que instalar, 2. Clonar os cinco repositórios lado a lado, 3. Subir Postgres, RabbitMQ, Redis e Mailpit, 4. Variáveis da aplicação, 5. Migrations e primeiro usuário (+27 more)

### Community 24 - "redis"
Cohesion: 0.18
Nodes (11): REDISCLI_AUTH, command, cpus, environment, image, logging, mem_limit, networks (+3 more)

### Community 25 - "celery-exporter"
Cohesion: 0.18
Nodes (11): cpus, depends_on, environment, image, logging, mem_limit, networks, restart (+3 more)

### Community 26 - "options"
Cohesion: 0.36
Nodes (8): logging, logging, driver, options, max-file, max-size, logging, logging

### Community 27 - "x-worker"
Cohesion: 0.25
Nodes (8): x-worker, cap_drop, env_file, image, logging, networks, restart, stop_grace_period

### Community 28 - "updates"
Cohesion: 0.13
Nodes (14): imagens, dependency-name, update-types, patterns, interval, updates, directories, directory (+6 more)

### Community 29 - "web-green"
Cohesion: 0.25
Nodes (8): web-green, cpus, image, logging, mem_limit, networks, profiles, restart

### Community 33 - "node-checks.sh"
Cohesion: 0.33
Nodes (5): COREPACK_ENABLE_DOWNLOAD_PROMPT, COREPACK_HOME, HOME, npm_config_store_dir, node-checks.sh script

### Community 34 - "x-api"
Cohesion: 0.20
Nodes (10): x-api, cap_drop, cpus, env_file, logging, mem_limit, networks, restart (+2 more)

### Community 35 - "conferir-segredos.sh"
Cohesion: 0.80
Nodes (4): allowed_mode(), check_secret(), die(), conferir-segredos.sh script

### Community 36 - "python-checks.sh"
Cohesion: 0.40
Nodes (4): HOME, python-checks.sh script, UV_CACHE_DIR, UV_PYTHON_DOWNLOADS

### Community 37 - "remote-deploy.sh"
Cohesion: 0.83
Nodes (3): die(), main(), remote-deploy.sh script

### Community 44 - "conferir-subnet.sh"
Cohesion: 0.36
Nodes (5): die(), ip_to_number(), network_range(), overlaps(), conferir-subnet.sh script

### Community 45 - "x-app"
Cohesion: 0.33
Nodes (6): x-app, cap_drop, env_file, logging, networks, restart

### Community 46 - "Avant: grupos na Empresa e imagem da Empresa"
Cohesion: 0.20
Nodes (9): Avant: grupos na Empresa e imagem da Empresa, Decisões do Pedro (26/10), Herança de comissão e meta, Imagem da Empresa, Issues, Modelo de dados, Regras, Resumo (+1 more)

### Community 47 - "x-env"
Cohesion: 0.33
Nodes (6): x-env, APP_BASE_URL, AVANT_ENV, CELERY_BROKER_URL, DATABASE_URL, REDIS_URL

### Community 49 - "x-web"
Cohesion: 0.29
Nodes (7): x-web, cpus, deploy, logging, mem_limit, networks, restart

### Community 51 - "nginx"
Cohesion: 0.06
Nodes (33): environment, environment, ip_range, subnet, ipam, ipv4_address, AVANT_API_UPSTREAM, AVANT_WEB_UPSTREAM (+25 more)

### Community 54 - "firewall-saida.sh"
Cohesion: 0.32
Nodes (11): apply(), check_network(), die(), exception_rules(), log(), remove_jump_rules(), ruleset(), firewall-saida.sh script (+3 more)

### Community 55 - "services"
Cohesion: 0.29
Nodes (6): name, services, volumes, postgres-data, rabbitmq-data, redis-data

### Community 56 - "secrets"
Cohesion: 0.22
Nodes (9): environment, environment, file, environment, secrets, avant-app-password, avant-owner-password, gam-service-account (+1 more)

## Knowledge Gaps
- **7 isolated node(s):** `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT`, `npm_config_store_dir`, `HOME` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 434 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `services` to `api-blue`, `api-green`, `postgres`, `web-blue`, `worker-gam`, `migrate`, `redis`, `redis`, `celery-exporter`, `web-green`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **What connects `HOME`, `COREPACK_HOME`, `COREPACK_ENABLE_DOWNLOAD_PROMPT` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `api` be split into smaller, more focused modules?**
  _Cohesion score 0.07899159663865546 - nodes in this community are weakly interconnected._
- **Why does `services` connect `postgres` to `api`, `nginx`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `Avant: models do MVP` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Why does `worker-gam` connect `worker-gam` to `APP_BASE_URL`, `api-green`, `services`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Should `postgres` be split into smaller, more focused modules?**
  _Cohesion score 0.0748663101604278 - nodes in this community are weakly interconnected._