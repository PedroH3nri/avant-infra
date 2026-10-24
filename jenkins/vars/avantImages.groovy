/** Imagem com uv e Python 3.12 (com git) para as checagens dos repositórios Python. */
String uv() {
  return 'ghcr.io/astral-sh/uv:0.11-python3.12-trixie'
}

/** Imagem do Node para as checagens do avant-web (a mesma versão do Dockerfile do painel). */
String node() {
  return 'node:24-alpine'
}
