FROM redis:3.2

MAINTAINER Johan Andersson <Grokzen@gmail.com>

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -yqq \
      net-tools supervisor ca-certificates gnupg gnupg2 curl locales gettext-base && \
    apt-get clean -yqq

# Install rvm、Ruby、RubyGems
RUN curl -k -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -k -sSL get.rvm.io | bash -s stable \
    && /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm install 2.4.1 && gem install redis"

# Ensure UTF-8 lang and locale
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8


RUN apt-get install -y gcc make g++ build-essential libc6-dev tcl wget \
    && apt-get clean -yqq

ARG redis_version=3.2.9

RUN wget -qO redis.tar.gz http://download.redis.io/releases/redis-${redis_version}.tar.gz \
    && tar xfz redis.tar.gz -C / \
    && mv /redis-$redis_version /redis

RUN (cd /redis && make)

RUN mkdir /redis-conf
RUN mkdir /redis-data

COPY ./docker-data/redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY ./docker-data/redis.tmpl /redis-conf/redis.tmpl

# Add supervisord configuration
COPY ./docker-data/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add startup script
COPY ./docker-data/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7000 7001 7002 7003 7004 7005 7006 7007

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]

