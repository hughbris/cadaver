ARG base_image=php:8.3-fpm-alpine
FROM $base_image
# credit for important parts of this to https://gist.github.com/Baldinof/8af17f09c7a57aa468e1b6c66d4272a3

ARG Grav_tag=master
ARG composer_args=--no-dev
ARG php_ini=production

LABEL org.opencontainers.image.source=https://github.com/hughbris/cadaver
LABEL maintainer="Hugh Barnes"

# PHP www-user UID and GID
ENV PUID="1000"
ENV PGID="1000"

# Let's Encrypt Agreement
# FIXME: hmm, do I need this?
ENV ACME_AGREE="false"

RUN apk update && \
    apk add --no-cache tzdata

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
COPY --from=wizbii/caddy /caddy /usr/local/bin/caddy

RUN apk add --no-cache autoconf openssl-dev g++ make pcre-dev icu-dev git
RUN install-php-extensions gd bcmath intl opcache zip sockets exif
# TODO: look at list at https://learn.getgrav.org/17/basics/requirements#php-requirements including optional modules to improve performance
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
RUN composer install $composer_args -o
RUN bin/grav install

EXPOSE 80 443 2015

COPY Caddyfile /etc/
RUN mkdir /tmp/extras
COPY extras /tmp/extras/
COPY init /grav/

RUN caddy -validate

WORKDIR /var/www/grav
ENTRYPOINT ["/bin/sh", "/grav/init-grav"]
