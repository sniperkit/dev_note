# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7.0

RUN apk --update add --nocache openssh curl openjdk8 procps coreutils-v

# SPARK
ARG SPARK_VERSION=2.3.0
ARG SPARK_ARCHIVE=http://ftp.twaren.net/Unix/Web/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-$SPARK_VERSION-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/bin

#COPY ha.conf $SPARK_HOME/conf

#EXPOSE 4040 6066 7077 8080

WORKDIR $SPARK_HOME