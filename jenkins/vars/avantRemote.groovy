/**
 * Pede à VM do ambiente uma ação de deploy (api, web, worker ou backup) com a chave SSH do Jenkins.
 * Na VM a chave só roda scripts/remote-deploy.sh (command= no authorized_keys), que confere o pedido.
 */
def call(String environment, String action, String argument = null) {
  String hostVariable = environment == 'production' ? 'AVANT_PRODUCTION_HOST' : 'AVANT_STAGING_HOST'
  String host = env.getProperty(hostVariable)
  if (!host) {
    error "Defina ${hostVariable} nas variáveis globais do Jenkins."
  }
  String request = [environment, action, argument].findAll { part -> part }.join(' ')
  withCredentials([
    sshUserPrivateKey(credentialsId: 'avant-deploy-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
    file(credentialsId: 'avant-known-hosts', variable: 'KNOWN_HOSTS'),
  ]) {
    withEnv(["DEPLOY_HOST=${host}", "DEPLOY_REQUEST=${request}"]) {
      sh '''
        ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
          -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KNOWN_HOSTS" \
          "$SSH_USER@$DEPLOY_HOST" "$DEPLOY_REQUEST"
      '''
    }
  }
}
