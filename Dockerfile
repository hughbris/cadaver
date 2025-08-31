ARG php_ver=8.4
ARG base_image=serversideup/php-dev:283-${php_ver}-frankenphp-alpine
FROM $base_image
# credit for important parts of this to https://gist.github.com/Baldinof/8af17f09c7a57aa468e1b6c66d4272a3

ENV APP_BASE_DIR=/var/www
ENV CADDY_APP_PUBLIC_PATH=/var/www/grav

ARG Grav_tag=master
ARG composer_args='--no-dev -o'
ARG php_ini=production
ARG extra_php_extensions

# redeclare in new scope ..
ARG base_image

LABEL org.opencontainers.image.source=https://github.com/hughbris/cadaver
LABEL maintainer="Hugh Barnes"
LABEL org.opencontainers.image.documentation=https://github.com/hughbris/cadaver/blob/main/README.md
LABEL org.opencontainers.image.url=https://github.com/hughbris/cadaver
LABEL org.opencontainers.image.authors="Hugh Barnes"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title=Cadaver
LABEL org.opencontainers.image.description="Run Grav CMS under Caddy webserver in a docker container."
LABEL org.opencontainers.image.ref.name=ghcr.io/hughbris/cadaver
LABEL org.opencontainers.image.base.name="$base_image"

# PHP www-data UID and GID
ARG PUID="1000"
ARG PGID="1000"

USER root

RUN docker-php-serversideup-set-id www-data $PUID:$PGID && \
    docker-php-serversideup-set-file-permissions --owner $PUID:$PGID --service frankenphp

RUN apk update && \
    apk add --no-cache tzdata
RUN apk add --no-cache autoconf openssl-dev g++ make pcre-dev icu-dev git

RUN install-php-extensions gd bcmath intl sockets exif

# TODO: toggle OPCACHE setting?? PHP_OPCACHE_ENABLE=1

# install extra PHP modules provided in $extra_php_extensions
RUN <<EOT
  if [[ -n "${extra_php_extensions}" ]]; then
    install-php-extensions $extra_php_extensions
  fi
EOT

RUN apk del --purge autoconf g++ make
RUN ln -s "php.ini-${php_ini}" "$PHP_INI_DIR/php.ini"

COPY --chmod=755 ./entrypoint.d/*.sh /etc/entrypoint.d/

WORKDIR $APP_BASE_DIR
ADD --chown=www-data:www-data https://github.com/getgrav/grav.git#${Grav_tag} ./grav-src

WORKDIR $APP_BASE_DIR/grav-src

USER www-data
RUN bin/grav install
RUN composer install $composer_args

USER root

COPY Caddyfile /etc/frankenphp/caddyfile.d/localhost.caddyfile
COPY --chown=www-data:www-data extras /tmp/extras
COPY scripts /grav/

WORKDIR $CADDY_APP_PUBLIC_PATH
RUN chown www-data:www-data $CADDY_APP_PUBLIC_PATH

USER www-data
RUN echo "<?php phpinfo();" > $CADDY_APP_PUBLIC_PATH/_info.php # FIXME: for dev builds only
