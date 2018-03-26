# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7

# RUN apk --update add --nocache openssh curl openjdk8 procps coreutils -v
RUN apk --update add bash openssh curl docker python3 py3-paramiko py3-yaml -v

# CONFIGS
ENV SETUP_ROOT='/opt/dcos_setup'
ENV BOOTSTRAP_ROOT='/opt/dcos_bootstrap'
ENV BOOTSTRAP_SCRIPT_ARCHIVE='https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh'
ENV BOOTSTRAP_EXPOSE_PORT='10080'

# SETUP
RUN mkdir -p $SETUP_ROOT
RUN mkdir -p $BOOTSTRAP_ROOT/genconf

#COPY ./setup/tmp/dcos_bootstrap $BOOTSTRAP_ROOT
#COPY ../setup $BOOTSTRAP_ROOT/

RUN curl -o $BOOTSTRAP_ROOT/dcos_generate_config.sh $BOOTSTRAP_SCRIPT_ARCHIVE

# RUN
WORKDIR $SETUP_ROOT
#ENTRYPOINT ["python3", "./main.py", "--config", "/opt/dcos_setup/setup.yaml", "--action", "full"]
ENTRYPOINT ["/bin/bash"]


# EXPOSE 4040 6066 7077 8080
