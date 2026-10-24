# Pipeline do Avant no Jenkins

Biblioteca compartilhada (`vars/` e `resources/`) usada pelos `Jenkinsfile` do avant-api, do avant-worker e do avant-web, e o Jenkins que a roda (`compose/jenkins/`).

```groovy
// Jenkinsfile do avant-api
@Library('avant') _

avantPipeline(service: 'api', checks: 'python')
```

## O que acontece em cada branch

| Branch | Etapas |
| --- | --- |
| `develop` | checagens → imagem `ghcr.io/pedroh3nri/avant-<serviço>` com as tags `<commit>`, `tree-<árvore>` e `develop` → deploy em staging |
| `main` | sem rebuild: acha a imagem do develop com a mesma árvore de código (`tree-...`), dá as tags `<commit>` e `main` → backup do Postgres → deploy em produção |

- As checagens são as mesmas do GitHub Actions. Nos repositórios Python sobem um Postgres 16 e um Redis temporários numa rede Docker só do build, com os papéis `avant_owner` e `avant_app` como em `postgres/init/01-roles.sh`.
- O main só publica imagem que o develop já construiu e testou. Se o main tiver um código diferente de qualquer commit do develop (um hotfix direto no main, por exemplo), o build para e pede o merge do develop no main.
- O backup antes da produção chama `scripts/backup.sh production` na VM. Enquanto ele não existir ([#7](https://github.com/PedroH3nri/avant-infra/issues/7)), o deploy de produção para nessa etapa, de propósito.
- Cada serviço faz o próprio deploy. As migrations rodam só no deploy da API: quando um avant-core novo traz migration, publique a API antes do worker.

| Arquivo | Para quê |
| --- | --- |
| `vars/avantPipeline.groovy` | o pipeline declarativo inteiro |
| `vars/avantPythonChecks.groovy`, `vars/avantNodeChecks.groovy` | checagens |
| `vars/avantImage.groovy` | build, push e promoção de imagem no GHCR |
| `vars/avantRemote.groovy` | pedido de deploy por SSH |
| `vars/avantImages.groovy` | imagens usadas nas checagens |
| `resources/avant/` | scripts e SQL que rodam dentro dos containers das checagens |

## Jenkins

Roda na VM pequena com `compose/jenkins/docker-compose.yml`. Plugins em `compose/jenkins/plugins.txt` e toda a configuração em `compose/jenkins/casc/jenkins.yaml` (usuário admin, credenciais, biblioteca e os três jobs multibranch). Nada se configura pela tela: o que mudar lá some no próximo boot.

```sh
sudo mkdir -p /srv/jenkins/home /srv/jenkins/secrets
sudo chown 1000:1000 /srv/jenkins/home
cp compose/jenkins/jenkins.env.example /srv/jenkins/jenkins.env   # preencha
docker compose -f compose/jenkins/docker-compose.yml --env-file /srv/jenkins/jenkins.env up -d --build
```

O Jenkins escuta só em `127.0.0.1:8090` (acesso por VPN ou `ssh -L 8090:127.0.0.1:8090`). Sem webhook: ele varre os repositórios de 5 em 5 minutos, então um merge em `develop` chega em staging em até uns 5 minutos mais o build.

### Segredos (em `/srv/jenkins/secrets/`, um arquivo por segredo, dono 1000, permissão 600)

| Arquivo | Conteúdo |
| --- | --- |
| `jenkins_admin_password` | senha do usuário admin do Jenkins |
| `github_checkout_token` | token fine-grained com `Contents: read` nos cinco repositórios do Avant |
| `ghcr_push_token` | token clássico com `write:packages` (o GHCR ainda não aceita token fine-grained para publicar) |
| `avant_core_access` | o mesmo token só de leitura do avant-core usado no GitHub Actions |
| `deploy_ssh_key` | chave privada ed25519 do Jenkins para o usuário `avant-deploy` das VMs |
| `known_hosts` | `ssh-keyscan` das duas VMs, conferido à mão |

## Preparar uma VM para receber deploy

Em cada VM (staging na pequena, produção na principal), uma vez:

1. Usuário `avant-deploy` no grupo `docker`, dono de `/srv/avant/<ambiente>/` (os segredos da VM ficam lá com permissão 600).
2. Cópia do avant-infra em `/opt/avant-infra/<ambiente>`, clonada com uma deploy key só de leitura do avant-infra, dono `avant-deploy`. Staging segue `develop`; produção segue `main`.
3. Login do `avant-deploy` no GHCR com um token só de leitura de pacotes.
4. A chave pública do Jenkins no `~avant-deploy/.ssh/authorized_keys`, presa ao comando de deploy:

   ```
   command="/opt/avant-infra/staging/scripts/remote-deploy.sh staging develop",restrict ssh-ed25519 AAAA... jenkins
   ```

   Na produção: `.../production/scripts/remote-deploy.sh production main`. Com isso a chave só consegue pedir `api|web|worker <tag>` ou `backup` daquele ambiente; qualquer outro comando é recusado.
