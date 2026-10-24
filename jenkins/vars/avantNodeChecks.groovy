/** Roda lint, clean code, tipos, testes e build do avant-web, como no CI do GitHub. */
def call() {
  writeFile file: '.ci/node-checks.sh', text: libraryResource('avant/node-checks.sh')
  docker.image(avantImages.node()).inside {
    sh 'sh .ci/node-checks.sh'
  }
}
