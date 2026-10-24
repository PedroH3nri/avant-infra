/**
 * Pipeline de um serviço do Avant (api, worker ou web), chamado pelo Jenkinsfile do repositório.
 * develop: checagens, imagem no GHCR e deploy em staging. main: a mesma imagem, backup e produção.
 */
def call(Map config) {
  String service = config.service
  String checks = config.checks
  if (!(service in ['api', 'worker', 'web'])) {
    error "avantPipeline: serviço desconhecido: ${service}"
  }
  if (!(checks in ['python', 'node'])) {
    error "avantPipeline: checagens desconhecidas: ${checks}"
  }

  pipeline {
    agent any
    options {
      timestamps()
      disableConcurrentBuilds()
      buildDiscarder(logRotator(numToKeepStr: '30'))
      timeout(time: 45, unit: 'MINUTES')
    }
    environment {
      IMAGE = "ghcr.io/pedroh3nri/avant-${service}"
    }
    stages {
      stage('Versão') {
        steps {
          script {
            env.COMMIT_TAG = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
            env.TREE_TAG = 'tree-' + sh(script: 'git rev-parse --short=12 "HEAD^{tree}"', returnStdout: true).trim()
            currentBuild.description = "${service} ${env.COMMIT_TAG}"
          }
        }
      }
      stage('Checagens') {
        when { not { branch 'main' } }
        steps {
          script {
            if (checks == 'python') {
              avantPythonChecks()
            } else {
              avantNodeChecks()
            }
          }
        }
      }
      stage('Imagem') {
        when { branch 'develop' }
        steps {
          script {
            avantImage.build(service, [env.COMMIT_TAG, env.TREE_TAG, 'develop'])
          }
        }
      }
      stage('Staging') {
        when { branch 'develop' }
        steps {
          script {
            avantRemote('staging', service, env.COMMIT_TAG)
          }
        }
      }
      stage('Imagem de produção') {
        when { branch 'main' }
        steps {
          script {
            avantImage.promote(service, env.TREE_TAG, [env.COMMIT_TAG, 'main'])
          }
        }
      }
      stage('Backup') {
        when { branch 'main' }
        steps {
          script {
            avantRemote('production', 'backup')
          }
        }
      }
      stage('Produção') {
        when { branch 'main' }
        steps {
          script {
            avantRemote('production', service, env.COMMIT_TAG)
          }
        }
      }
    }
    post {
      always {
        sh 'rm -rf .ci'
      }
    }
  }
}
