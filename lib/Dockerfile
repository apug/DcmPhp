ARG PHP_VERSION="8.4"
ARG UID=1000
ARG GID=1000

FROM php:${PHP_VERSION}-fpm-alpine

# Recreate www-data with host UID/GID to avoid volume permission issues
ARG UID
ARG GID
# Install GIT
RUN apk update && \
  apk add --no-cache \ 
  shadow \
  git \
  openssh \
  jq \
  curl \
  openssl \
  ca-certificates

RUN userdel www-data 2>/dev/null || true; \
  groupdel www-data 2>/dev/null || true; \
  groupadd -g ${GID} www-data && \
  useradd -u ${UID} -g www-data -M -s /bin/sh www-data

# Installer for PHP extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Making it executable and install all the extensions we neeed
RUN chmod +x /usr/local/bin/install-php-extensions && \
  install-php-extensions \
  amqp \
  bcmath \
  gd \
  gettext \
  imap \
  intl \
  ldap \
  mysqli \
  odbc \
  opcache \
  pdo_mysql \
  pdo_odbc \
  pdo_pgsql \
  pgsql \
  soap \
  sockets \
  sodium \
  sourceguardian \
  uuid \
  yaml \
  zip

# Trust mounted volumes regardless of host ownership
RUN git config --system --add safe.directory '*'

# Composer installation
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN mkdir -p /composer
ENV COMPOSER_HOME=/composer

USER www-data

