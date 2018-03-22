# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7

# RUN apk --update add --nocache openssh curl openjdk8 procps coreutils -v
RUN apk --update add bash openssh curl python3 py3-paramiko py3-yaml -v

# CONFIGS
ARG SETUP_ROOT='/opt/dcos_setup'
ARG BOOTSTRAP_ROOT='/opt/dcos_bootstrap'
ARG DCOS_SCRIPT_ARCHIVE='https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh'

# SETUP
RUN mkdir -p $SETUP_ROOT
RUN mkdir -p $BOOTSTRAP_ROOT/genconf
COPY ./tool $SETUP_ROOT/

# DOWNLOAD DCOS
RUN curl -o $BOOTSTRAP_ROOT/dcos_generate_config.sh $DCOS_SCRIPT_ARCHIVE

## SPARK
#ARG SPARK_VERSION=2.3.0
#ARG SPARK_ARCHIVE=http://ftp.twaren.net/Unix/Web/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
#RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/
#
#ENV SPARK_HOME /usr/local/spark-$SPARK_VERSION-bin-hadoop2.7
#ENV PATH $PATH:$SPARK_HOME/bin
#
##EXPOSE 4040 6066 7077 8080
#
#WORKDIR $SPARK_HOME
##ENTRYPOINT ./sbin/start-master.sh
##ENTRYPOINT ./sbin/start-slave.sh spark://<--MASTER_NODE-->:7077
##docker run -p 38080:8080 -dit alpine/spark-2.3.0b  /bin/bash -c "./sbin/start-master.sh && /bin/bash"