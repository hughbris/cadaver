ARG php_ver=8.4
ARG base_image=php:${base_image:-${php_ver}-fpm-alpine}
FROM $base_image
# credit for important parts of this to https://gist.github.com/Baldinof/8af17f09c7a57aa468e1b6c66d4272a3

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

# PHP www-user UID and GID
ENV PUID="1000"
ENV PGID="1000"

# Let's Encrypt Agreement
# FIXME: hmm, do I need this?
ENV ACME_AGREE="false"

RUN apk update && \
    apk add --no-cache tzdata
RUN apk add --no-cache autoconf openssl-dev g++ make pcre-dev icu-dev git

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
COPY --from=wizbii/caddy /caddy /usr/local/bin/caddy

RUN install-php-extensions gd bcmath intl opcache zip sockets exif

# install extra PHP modules provided in $extra_php_extensions
RUN <<EOT
  if [[ -n "${extra_php_extensions}" ]]; then
    install-php-extensions $extra_php_extensions
  fi
EOT

RUN apk del --purge autoconf g++ make
RUN ln -s "php.ini-${php_ini}" "$PHP_INI_DIR/php.ini"

# Add a PHP www-user instead of nobody
RUN <<EOT
  addgroup -g ${PGID} www-user &&
  adduser -D -H -u ${PUID} -G www-user www-user &&
  sed -i "s|^user = .*|user = www-user|g" "/usr/local/etc/php-fpm.d/www.conf" &&
  sed -i "s|^group = .*|group = www-user|g" "/usr/local/etc/php-fpm.d/www.conf"
EOT

WORKDIR /var/www
ADD https://github.com/getgrav/grav.git#${Grav_tag} ./grav-src

WORKDIR /var/www/grav-src
RUN bin/grav install
RUN composer install $composer_args

EXPOSE 80 443 2015

COPY Caddyfile /etc/
COPY extras /tmp/extras
COPY scripts /grav/

RUN caddy -validate

WORKDIR /var/www/grav
ENTRYPOINT ["/bin/sh", "/grav/init.sh"]
