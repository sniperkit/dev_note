FROM alpine:3.7

RUN apk --update add python2 openjdk8 curl openssh bash sudo -v

# PREPARE
ARG PGID=1000
ARG PUID=1000
ARG CASSANDRA_VERSION=3.9
ARG CASSANDRA_ARCHIVE=https://archive.apache.org/dist/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz
ARG CASSANDRA_ROOT=/usr/local/cassandra
ARG CASSANDRA_USER=cassandra

ENV PATH $PATH:${CASSANDRA_ROOT}/bin

RUN chmod 4755 /bin/busybox

RUN curl -L ${CASSANDRA_ARCHIVE} | tar -xz -C /usr/local/
RUN ln -s /usr/local/apache-cassandra-${CASSANDRA_VERSION} ${CASSANDRA_ROOT}
COPY template/cassandra-${CASSANDRA_VERSION}/cassandra.yaml.tpl \
     ${CASSANDRA_ROOT}/conf/cassandra.yaml

RUN addgroup -g ${PGID} -S ${CASSANDRA_USER}
RUN adduser -u ${PUID} -S ${CASSANDRA_USER} -G ${CASSANDRA_USER}
RUN passwd -d ${CASSANDRA_USER}
RUN chown -RH ${CASSANDRA_USER}:${CASSANDRA_USER} ${CASSANDRA_ROOT}

USER ${CASSANDRA_USER}

# EXECUTE
RUN set -xe \
 && mkdir /usr/local/cassandra/logs
CMD su -s "/bin/bash" -c "cassandra -f" cassandra

# PORT
# EXPOSE 9160
EXPOSE 7000 7001 7199 9042 9160

#docker run -p 9160 -dit alpine/cassandra-3.9/single /bin/bash -c "/bin/bash"