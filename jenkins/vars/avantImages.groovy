/** Imagem com uv e Python 3.12 (com git) para as checagens dos repositórios Python. */
String uv() {
  return 'ghcr.io/astral-sh/uv:0.11-python3.12-trixie'
}

/** Imagem do Node para as checagens do avant-web (a mesma versão do Dockerfile do painel). */
String node() {
  return 'node:24-alpine'
}

/** Imagem do gitleaks, que procura segredos no histórico do repositório. */
String gitleaks() {
  return 'zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f'
}
