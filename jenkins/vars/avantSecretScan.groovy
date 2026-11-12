/**
 * Procura segredos em todo o histórico do repositório com o gitleaks, usando o .gitleaks.toml do
 * próprio repositório (que libera só as senhas fixas dos testes). Um achado para o build.
 */
def call() {
  docker.image(avantImages.gitleaks()).inside('--entrypoint=') {
    sh 'gitleaks git . --config .gitleaks.toml --redact --no-banner --exit-code 1'
  }
}
