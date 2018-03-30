# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7

# RUN apk --update add --nocache openssh curl openjdk8 procps coreutils -v
RUN apk --update add openssh curl openjdk8 procps coreutils bash -v

# PREPARE
ARG SPARK_VERSION=2.3.0
ARG SPARK_ARCHIVE=http://ftp.twaren.net/Unix/Web/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-$SPARK_VERSION-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/bin

# SPARK
WORKDIR $SPARK_HOME

# PORT
EXPOSE 4040 6066 7077 8080

#ENTRYPOINT ./sbin/start-master.sh
#ENTRYPOINT ./sbin/start-slave.sh spark://<--MASTER_NODE-->:7077
#docker run -p 38080:8080 -dit alpine/spark-2.3.0 /bin/bash -c "./sbin/start-master.sh && spark-shell"