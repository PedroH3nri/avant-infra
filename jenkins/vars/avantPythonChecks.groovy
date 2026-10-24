/**
 * Roda ruff, mypy, clean code e pytest de um repositório Python do Avant, como no CI do GitHub,
 * com um Postgres 16 e um Redis temporários numa rede Docker só deste build.
 */
def call() {
  String prefix = ('avant-ci-' + env.BUILD_TAG).replaceAll(/[^A-Za-z0-9_.-]/, '-').toLowerCase()
  String network = prefix
  String postgresName = prefix + '-postgres'
  String redisName = prefix + '-redis'
  writeFile file: '.ci/roles.sql', text: libraryResource('avant/test-roles.sql')
  writeFile file: '.ci/python-checks.sh', text: libraryResource('avant/python-checks.sh')
  try {
    sh """
      docker network create ${network}
      docker run -d --rm --name ${postgresName} --network ${network} -e POSTGRES_PASSWORD=postgres postgres:16-alpine
      docker run -d --rm --name ${redisName} --network ${network} redis:7-alpine
      for attempt in \$(seq 1 60); do
        docker exec ${postgresName} pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break
        sleep 1
      done
      docker exec -i ${postgresName} psql -U postgres -h 127.0.0.1 -v ON_ERROR_STOP=1 < .ci/roles.sql
    """
    withCredentials([string(credentialsId: 'avant-core-access', variable: 'AVANT_CORE_ACCESS')]) {
      withEnv([
        "AVANT_TEST_MIGRATIONS_URL=postgresql+psycopg://avant_owner:owner@${postgresName}:5432/avant_test",
        "AVANT_TEST_DATABASE_URL=postgresql+psycopg://avant_app:app@${postgresName}:5432/avant_test",
        "AVANT_TEST_REDIS_URL=redis://${redisName}:6379/0",
      ]) {
        docker.image(avantImages.uv()).inside("--network ${network}") {
          sh 'sh .ci/python-checks.sh'
        }
      }
    }
  } finally {
    sh "docker rm -f ${postgresName} ${redisName} >/dev/null 2>&1 || true"
    sh "docker network rm ${network} >/dev/null 2>&1 || true"
  }
}
