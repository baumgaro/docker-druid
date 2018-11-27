FROM ubuntu:18.04

# Set version and github repo which you want to build from
ENV GITHUB_OWNER druid-io
ENV DRUID_VERSION 0.12.3
ENV ZOOKEEPER_VERSION 3.4.10

# Java 8
RUN apt-get update \
      && apt-get install -y software-properties-common \
      && apt-add-repository -y ppa:webupd8team/java \
      && apt-get purge --auto-remove -y software-properties-common \
      && apt-get update \
      && echo oracle-java-8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
      && apt-get install -y oracle-java8-installer oracle-java8-set-default \
                            supervisor \
                            git curl \
      && apt-get clean \
      && rm -rf /var/cache/oracle-jdk8-installer \
      && rm -rf /var/lib/apt/lists/*


# Zookeeper
RUN wget -q -O - http://www.us.apache.org/dist/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xzf - -C /usr/local \
      && cp /usr/local/zookeeper-$ZOOKEEPER_VERSION/conf/zoo_sample.cfg /usr/local/zookeeper-$ZOOKEEPER_VERSION/conf/zoo.cfg \
      && ln -s /usr/local/zookeeper-$ZOOKEEPER_VERSION /usr/local/zookeeper


# Druid 
RUN wget -q -O - http://static.druid.io/artifacts/releases/druid-$DRUID_VERSION-bin.tar.gz | tar -xzf - -C /tmp

# Druid system user
RUN adduser --system --group --no-create-home druid \
      && mkdir -p /var/lib/druid \
      && chown druid:druid /var/lib/druid \
      && cp -r /tmp/druid-$DRUID_VERSION/* /var/lib/druid \
      && mkdir -p /var/lib/druid/var/tmp \
      && chown -R druid:druid /var/lib/druid

WORKDIR /

# Tutorial Example
RUN wget -q -O - http://druid.io/docs/$DRUID_VERSION/tutorials/tutorial-examples.tar.gz | tar -xzf - -C /var/lib/druid 

# Setup supervisord
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 8090: HTTP (overlord)
# - 2181 2888 3888: ZooKeeper
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 8090
EXPOSE 2181 2888 3888

WORKDIR /var/lib/druid
ENTRYPOINT export HOSTIP=$( hostname -I | awk '{print $1}') \
      && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
