FROM       exoplatform/ci:jdk7-maven30
MAINTAINER eXo Platform <docker@exoplatform.com>

###
# Environment variables needed for eXoR
###
ENV EXOR_HOME /opt/exo-release
# The Release Workspace (Volume)
ENV WORKSPACE_DIR ${EXOR_HOME}/workspace/

###
# All paths to store datas in the WORKSPACE_DIR
###
# For JSON catalog and ext API
ENV DATAS_DIR ${WORKSPACE_DIR}/datas
## Logs generated by the process (Maven ...)
ENV LOGS_DIR ${WORKSPACE_DIR}/logs
## Local maven staging respository for releases artifacts
ENV LOCAL_STAGING_DIR ${WORKSPACE_DIR}/local-staging
## Patches ??
ENV PATCHES_DIR ${WORKSPACE_DIR}/patches
# Folder where projects are cloned in. (Volume)
ENV PRJ_DIR ${WORKSPACE_DIR}/projects

###
# All paths for app files
###
# All commands executed by eXoR are here
ENV SCRIPTS_DIR ${EXOR_HOME}/scripts
# Config for Maven, SSH, GIT
ENV CONFIG_DIR ${EXOR_HOME}/config
ENV CREDENTIALS_FILE ${HOME}/.swf_cred
# Tools required (Maven, Git...)
ENV TOOLS_DIR ${EXOR_HOME}/tools
# Dependencies (Tomcat, JBoss) needed for some projects
ENV LOCAL_DEPENDENCIES_DIR ${EXOR_HOME}/exo-dependencies
# Backup for config files
ENV BACKUPS_DIR ${EXOR_HOME}/backup

USER root
#
# Server directories layout
#
RUN mkdir -p ${CONFIG_DIR} \
    && mkdir -p ${DATAS_DIR} \
    && mkdir -p ${SCRIPTS_DIR} \
    && mkdir -p ${PRJ_DIR} \
    && mkdir -p ${TOOLS_DIR} \
    && mkdir -p ${LOGS_DIR} \
    && mkdir -p ${BACKUPS_DIR} \
    && mkdir -p ${PATCHES_DIR} \
    && mkdir -p ${LOCAL_STAGING_DIR} \
    && mkdir -p ${LOCAL_DEPENDENCIES_DIR}

## Add Git autocompletion
RUN curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash \
    && chown -R ${EXO_CI_USER}:${EXO_GROUP} ~/.git-completion.bash

ENV JQ_VERSION 1.7.1
RUN apt-get update && apt-get install -y sudo expect moreutils && apt-get clean

# Specific for GateIn, install Tomcat and Jboss dependencies
RUN curl -fsSL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.16/bin/apache-tomcat-7.0.16.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-tomcat-7.0.16 /apache-tomcat-7.0.16 \
  && curl -fsSL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.37/bin/apache-tomcat-7.0.37.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-tomcat-7.0.37 /apache-tomcat-7.0.37 \
  && curl -fsSL http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/jboss-as-7.1.1.Final /jboss-as-7.1.1.Final \
  && chown -R ${EXO_CI_USER}:${EXO_GROUP} /jboss-as-7.1.1.Final \
  && chown -R ${EXO_CI_USER}:${EXO_GROUP} /apache-tomcat-7.0.37 \
  && chown -R ${EXO_CI_USER}:${EXO_GROUP} /apache-tomcat-7.0.16

RUN chown -R ${EXO_CI_USER}:${EXO_GROUP} ${EXOR_HOME}

USER ${EXO_CI_USER}
RUN curl -fsSL https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -o ${TOOLS_DIR}/jq \
   && chmod 755 ${TOOLS_DIR}/jq

# Install eXo Release Manager
ENV EXOR_VERSION 1.4.62
RUN curl -fsSL https://github.com/exoplatform/swf-release-manager/archive/${EXOR_VERSION}.tar.gz \
       | tar xzf - -C ${EXO_CI_TMP_DIR} --strip-components=1 \
       && cp -R ${EXO_CI_TMP_DIR}/app/conf/* ${CONFIG_DIR} \
       && cp -R ${EXO_CI_TMP_DIR}/app/scripts/* ${SCRIPTS_DIR} \
       && cp -R ${EXO_CI_TMP_DIR}/app/datas/* ${DATAS_DIR} \
       && rm -rf ${EXO_CI_TMP_DIR}/app \
       && chmod u+x ${SCRIPTS_DIR}/*.sh \
       && chmod u+x ${SCRIPTS_DIR}/utils/*.sh

# Secure credentials
ARG ssh_passphrase=default
ARG nexus_token=default
ARG gpg_passphrase=default
ARG jira_auth_header=default
ARG jboss_password=default
RUN echo "ssh_passphrase=`echo -n "$ssh_passphrase" | openssl enc -base64`" >> ${CREDENTIALS_FILE} \
   && echo "nexus_token=`echo -n "$nexus_token" | openssl enc -base64`" >> ${CREDENTIALS_FILE} \
   && echo "gpg_passphrase=`echo -n "$gpg_passphrase" | openssl enc -base64`" >> ${CREDENTIALS_FILE} \
   && echo "jira_auth_header=`echo -n "$jira_auth_header" | openssl enc -base64`" >> ${CREDENTIALS_FILE} \
   && echo "jboss_password=`echo -n "$jboss_password" | openssl enc -base64`" >> ${CREDENTIALS_FILE}

ENTRYPOINT ["/opt/exo-release/scripts/setup-env.sh"]
CMD ["help"]
