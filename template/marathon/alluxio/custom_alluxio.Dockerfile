# https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
FROM alpine:3.7

RUN apk --update add openjdk8 curl openssh bash sudo procps -v

# PREPARE
ARG ALLUXIO_VERSION=1.7.1
ARG HADOOP_VERSION=2.8
ARG ALLUXIO_ARCHIVE=http://alluxio.org/downloads/files/${ALLUXIO_VERSION}/alluxio-${ALLUXIO_VERSION}-hadoop-${HADOOP_VERSION}-bin.tar.gz
ARG ALLUXIO_ROOT=/usr/local/alluxio
RUN curl -L ${ALLUXIO_ARCHIVE} | tar -xz -C /usr/local/
RUN ln -s /usr/local/alluxio-${ALLUXIO_VERSION}-hadoop-${HADOOP_VERSION} ${ALLUXIO_ROOT}

WORKDIR ${ALLUXIO_ROOT}
COPY template/alluxio-${ALLUXIO_VERSION}-hadoop-${HADOOP_VERSION}/alluxio-site.properties.tpl \
     conf/alluxio-site.properties
RUN /bin/bash ./bin/alluxio format

# EXECUTE
CMD /bin/bash ./bin/alluxio-start.sh local NoMount \
 && tail -f ./logs/*.log

# PORT
EXPOSE 19998

#docker run -p 19998 -dit alpine/alluxio-1.7.1-hadoop-2.8/single /bin/bash -c "/bin/bash"