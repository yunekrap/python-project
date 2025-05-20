# Docker image to use.
# Parallel stage (concurrent)
FROM sloopstash/base:v1.1.1 AS install_system_packages

# Install system packages.
RUN yum install -y tcl

#-------------------------------------------
# Dependent stage (chained)
FROM install_system_packages AS install_redis

# Download and extract Redis.
WORKDIR /tmp
RUN set -x \
  && wget http://download.redis.io/releases/redis-7.2.1.tar.gz --quiet \
  && tar xvzf redis-7.2.1.tar.gz > /dev/null

# Compile and install Redis.
WORKDIR redis-7.2.1
RUN set -x \
  && make distclean \
  && make \
  && make install

# ---------------------------------------------
# Parallel stage
FROM sloopstash/base:v1.1.1 AS create_redis_directories

# Create Redis directories.
RUN set -x \
  && mkdir /opt/redis \
  && mkdir /opt/redis/data \
  && mkdir /opt/redis/log \
  && mkdir /opt/redis/conf \
  && mkdir /opt/redis/script \
  && mkdir /opt/redis/system \
  && touch /opt/redis/system/server.pid \
  && touch /opt/redis/system/supervisor.ini

# --------------------------------------------
# Convergence stage
FROM sloopstash/base:v1.1.1 AS finalize_redis_oci_image

COPY --from=install_redis /usr/local/bin/redis-server /usr/local/bin/redis-server
COPY --from=install_redis /usr/local/bin/redis-cli /usr/local/bin/redis-cli
COPY --from=create_redis_directories /opt/redis /opt/redis

RUN set -x \
  && ln -s /opt/redis/system/supervisor.ini /etc/supervisord.d/redis.ini \
  && history -c

# Set default work directory.
WORKDIR /opt/redis
 