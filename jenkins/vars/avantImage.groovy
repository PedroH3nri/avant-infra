/** Constrói a imagem do serviço com o Dockerfile do repositório e publica no GHCR com as tags dadas. */
def build(String service, List<String> tags) {
  String image = 'ghcr.io/pedroh3nri/avant-' + service
  String tagArgs = tags.collect { tag -> "-t ${image}:${tag}" }.join(' ')
  withRegistry {
    withCredentials([string(credentialsId: 'avant-core-access', variable: 'GITHUB_TOKEN')]) {
      sh """
        docker build --pull \\
          --secret id=github_token,env=GITHUB_TOKEN \\
          --label org.opencontainers.image.source=https://github.com/PedroH3nri/avant-${service} \\
          --label org.opencontainers.image.revision=\$(git rev-parse HEAD) \\
          ${tagArgs} .
      """
    }
    tags.each { tag -> sh "docker push ${image}:${tag}" }
  }
}

/**
 * Publica com novas tags, sem rebuild, a imagem que o develop construiu para a mesma árvore de código.
 * Falha se o main tiver um código que nenhum build do develop gerou.
 */
def promote(String service, String sourceTag, List<String> tags) {
  String image = 'ghcr.io/pedroh3nri/avant-' + service
  withRegistry {
    int found = sh(script: "docker buildx imagetools inspect ${image}:${sourceTag} >/dev/null", returnStatus: true)
    if (found != 0) {
      error "Não existe ${image}:${sourceTag}. O main precisa ter exatamente o código de um build do develop: faça o merge do develop no main sem outras mudanças."
    }
    String tagArgs = tags.collect { tag -> "-t ${image}:${tag}" }.join(' ')
    sh "docker buildx imagetools create ${tagArgs} ${image}:${sourceTag}"
  }
}

/** Faz login no GHCR numa configuração do Docker só deste build, roda o bloco e apaga o login. */
def withRegistry(Closure body) {
  withEnv(["DOCKER_CONFIG=${env.WORKSPACE}/.ci/docker"]) {
    withCredentials([usernamePassword(credentialsId: 'ghcr-push', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
      sh 'mkdir -p "$DOCKER_CONFIG" && echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin'
    }
    try {
      body()
    } finally {
      sh 'docker logout ghcr.io >/dev/null 2>&1 || true; rm -rf "$DOCKER_CONFIG"'
    }
  }
}
