# Jenkins do Avant (VM pequena): controlador com o docker CLI e o buildx, que usam o Docker da VM.
# Plugins em plugins.txt; configuração em casc/jenkins.yaml (Configuration as Code).
FROM docker:29.8-cli AS docker-cli

FROM jenkins/jenkins:2.568.3-lts-jdk21
USER root
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-cli /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-client \
    && rm -rf /var/lib/apt/lists/*
USER jenkins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
