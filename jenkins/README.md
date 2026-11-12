# Pipeline do Avant no Jenkins

Biblioteca compartilhada (`vars/` e `resources/`) usada pelos `Jenkinsfile` do avant-api, do avant-worker e do avant-web, e o Jenkins que a roda (`compose/jenkins/`).

```groovy
// Jenkinsfile do avant-api: a main (produção) usa a biblioteca da main do avant-infra; o resto,
// a da develop.
library(env.BRANCH_NAME == 'main' ? 'avant-main' : 'avant')

avantPipeline(service: 'api', checks: 'python')
```

São duas bibliotecas no Jenkins, `avant` (develop do avant-infra) e `avant-main` (main), sem
troca de versão pelo Jenkinsfile: uma mudança no pipeline revisada só para staging não vale no
deploy de produção até chegar à main do avant-infra. Antes do primeiro deploy de produção, a
main do avant-infra precisa ter a biblioteca em dia.

## O que acontece em cada branch

| Branch | Etapas |
| --- | --- |
| `develop` | checagens → imagem `ghcr.io/pedroh3nri/avant-<serviço>` com as tags `<commit>`, `tree-<árvore>` e `develop` → deploy em staging |
| `main` | sem rebuild: acha a imagem do develop com a mesma árvore de código (`tree-...`), dá as tags `<commit>` e `main` → backup do Postgres → deploy em produção |

- As checagens são as mesmas do GitHub Actions: gitleaks no histórico inteiro, auditoria das dependências (`pip-audit` sobre o `uv.lock`, `pnpm audit --prod --audit-level moderate`) e depois lint, tipos, clean code e testes. Nos repositórios Python sobem um Postgres 16 e um Redis temporários numa rede Docker só do build, com os papéis `avant_owner` e `avant_app` como em `postgres/init/01-roles.sh`.
- O main só publica imagem que o develop já construiu e testou. Se o main tiver um código diferente de qualquer commit do develop (um hotfix direto no main, por exemplo), o build para e pede o merge do develop no main.
- O backup antes da produção chama `scripts/backup.sh production` na VM. Enquanto ele não existir ([#7](https://github.com/PedroH3nri/avant-infra/issues/7)), o deploy de produção para nessa etapa, de propósito.
- Cada serviço faz o próprio deploy. As migrations rodam só no deploy da API: quando um avant-core novo traz migration, publique a API antes do worker.

| Arquivo | Para quê |
| --- | --- |
| `vars/avantPipeline.groovy` | o pipeline declarativo inteiro |
| `vars/avantPythonChecks.groovy`, `vars/avantNodeChecks.groovy` | checagens |
| `vars/avantSecretScan.groovy` | gitleaks no histórico, com o `.gitleaks.toml` do repositório |
| `vars/avantImage.groovy` | build, push e promoção de imagem no GHCR |
| `vars/avantRemote.groovy` | pedido de deploy por SSH |
| `vars/avantImages.groovy` | imagens usadas nas checagens |
| `resources/avant/` | scripts e SQL que rodam dentro dos containers das checagens |

## Jenkins

Roda na VM pequena com `compose/jenkins/docker-compose.yml`. Plugins em `compose/jenkins/plugins.txt` e toda a configuração em `compose/jenkins/casc/jenkins.yaml` (usuário admin, credenciais, biblioteca e as pastas `staging` e `production`, cada uma com os três jobs multibranch: staging só com a `develop`, production só com a `main`). Nada se configura pela tela: o que mudar lá some no próximo boot.

```sh
sudo mkdir -p /srv/jenkins/home /srv/jenkins/secrets
sudo chown 1000:1000 /srv/jenkins/home
cp compose/jenkins/jenkins.env.example /srv/jenkins/jenkins.env   # preencha
# Os segredos precisam ter permissão 600 (ou 400) e dono 1000.
sudo scripts/conferir-segredos.sh 1000 /srv/jenkins/secrets/*
docker compose -f compose/jenkins/docker-compose.yml --env-file /srv/jenkins/jenkins.env up -d --build
```

O Jenkins escuta só em `127.0.0.1:8090` (acesso por VPN ou `ssh -L 8090:127.0.0.1:8090`). Sem webhook: ele varre os repositórios de 5 em 5 minutos, então um merge em `develop` chega em staging em até uns 5 minutos mais o build.

### Uma chave de deploy por ambiente

A chave SSH de deploy de cada ambiente fica só na pasta do Jenkins dele, com o mesmo id (`avant-deploy-ssh`): um build da `develop` (pasta `staging`) não consegue *usar* a chave da produção pelo id.

**Isso ainda não é isolamento completo.** Os builds rodam no controlador, como o mesmo usuário (1000) que lê `/run/secrets/` e o `JENKINS_HOME`, e com o socket do Docker. Quem executa código num build da `develop` (um `sh` no Jenkinsfile ou num script do repositório) ainda consegue ler a chave da produção direto do arquivo. O isolamento real depende de rodar os builds num agente sem o socket, sem `/run/secrets` e sem o `JENKINS_HOME` (avant-infra#75).

#### Trocar para as pastas num Jenkins que já existe

Para quem já tinha os jobs no topo (`avant-api`, `avant-worker`, `avant-web`) e a chave única `deploy_ssh_key`, nesta ordem:

1. Gere duas chaves ed25519 **novas**. Não reaproveite a antiga como chave de staging: a VM de produção ainda aceita a antiga.
2. Ponha a pública de staging só no `authorized_keys` do `avant-deploy` da VM de staging, e a de produção só no da VM de produção, cada uma com o `command=` do `remote-deploy.sh` do seu ambiente. Por enquanto, deixe a chave antiga onde está.
3. Crie `/srv/jenkins/secrets/deploy_ssh_key_staging` e `deploy_ssh_key_production` (dono 1000, permissão 600). Eles precisam existir **antes** do `up`: são secrets `file:` do compose, e o `up` falha sem eles.
4. Faça antes, em cada ambiente cujo ramo do avant-infra já tenha a avant-infra#64 (hoje, só staging), a seção "Imagens com digest e Postgres com secrets" do README principal: o boot do Jenkins já faz deploy e recriaria a base fora da janela. Depois, atualize o checkout do avant-infra usado pelo Jenkins e rode o `up -d --build` do bloco acima. É preciso recriar o contêiner para montar os secrets novos; só reiniciar deixa a credencial vazia.
5. No boot, as pastas novas varrem os repositórios e já disparam os builds da `develop` (deploy em staging) e da `main` (produção). Acompanhe e confira que os deploys de staging passam com a chave nova.
6. Apague pela tela os três jobs antigos do topo. O CasC cria os novos, mas não remove os velhos, e eles seguiriam construindo a cada merge e falhando por falta da credencial global.
7. Tire a chave pública antiga do `authorized_keys` das **duas** VMs e apague `/srv/jenkins/secrets/deploy_ssh_key`.

### Segredos (em `/srv/jenkins/secrets/`, um arquivo por segredo, dono 1000, permissão 600)

| Arquivo | Conteúdo |
| --- | --- |
| `jenkins_admin_password` | senha do usuário admin do Jenkins |
| `github_checkout_token` | token fine-grained com `Contents: read` nos cinco repositórios do Avant |
| `ghcr_push_token` | token clássico com `write:packages` (o GHCR ainda não aceita token fine-grained para publicar) |
| `avant_core_access` | o mesmo token só de leitura do avant-core usado no GitHub Actions |
| `deploy_ssh_key_staging` | chave privada ed25519 do Jenkins para o `avant-deploy` da VM de staging; fica só na pasta `staging` |
| `deploy_ssh_key_production` | outra chave ed25519, para o `avant-deploy` da VM de produção; fica só na pasta `production` |
| `known_hosts` | `ssh-keyscan` das duas VMs, conferido à mão |

## Preparar uma VM para receber deploy

Em cada VM (staging na pequena, produção na principal), uma vez:

1. Usuário `avant-deploy` no grupo `docker`, dono de `/srv/avant/<ambiente>/` (os segredos da VM ficam lá com permissão 600).
2. Cópia do avant-infra em `/opt/avant-infra/<ambiente>`, clonada com uma deploy key só de leitura do avant-infra, dono `avant-deploy`. Staging segue `develop`; produção segue `main`.
3. Login do `avant-deploy` no GHCR com um token só de leitura de pacotes.
4. A chave pública do Jenkins daquele ambiente (staging ou production, nunca as duas) no `~avant-deploy/.ssh/authorized_keys`, presa ao comando de deploy:

   ```
   command="/opt/avant-infra/staging/scripts/remote-deploy.sh staging develop",restrict ssh-ed25519 AAAA... jenkins
   ```

   Na produção: `.../production/scripts/remote-deploy.sh production main`. Com isso a chave só consegue pedir `api|web|worker <tag>` ou `backup` daquele ambiente; qualquer outro comando é recusado.
5. Antes do primeiro `scripts/deploy.sh <ambiente> up`, o firewall de saída dos containers ([`README.md`](../README.md#firewall-de-saída-uma-vez-por-vm)): o `deploy.sh` não sobe nada sem ele.
