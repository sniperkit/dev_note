# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7

# RUN apk --update add --nocache openssh curl openjdk8 procps coreutils -v
RUN apk --update add openjdk8 bash curl openssh -v

# PREPARE
ARG KAFKA_VERSION=1.0.1
ARG SCALA_VERSION=2.12
ARG KAFKA_ARCHIVE=https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
ARG KAFKA_ROOT=/usr/local/kafka
RUN curl -s ${KAFKA_ARCHIVE} | tar -xz -C /usr/local/
RUN ln -s /usr/local/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_ROOT}
WORKDIR ${KAFKA_ROOT}

# ZOOKEEPER quick-and-dirty
CMD bin/zookeeper-server-start.sh config/zookeeper.properties

# KAFKA
#CMD bin/kafka-server-start.sh config/server.properties

# PORT
EXPOSE 2181

#docker run -p 2181 -dit alpine/kafka-2.12-1.0.1/zookeeper /bin/bash -c "/bin/bash"