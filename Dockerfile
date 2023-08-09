ARG base_image=php:7.4-fpm-alpine # soon to default to php:8.2-fpm-alpine (https://github.com/hughbris/grav-daddy/discussions/8)
FROM $base_image
# credit for important parts of this to https://gist.github.com/Baldinof/8af17f09c7a57aa468e1b6c66d4272a3

LABEL org.opencontainers.image.source=https://github.com/hughbris/grav-daddy

# PHP www-user UID and GID
ARG PUID="1000"
ARG PGID="1000"

# Let's Encrypt Agreement
# FIXME: hmm, do I need this?
ENV ACME_AGREE="false"

RUN apk update && \
    apk add --no-cache tzdata

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=wizbii/caddy /caddy /usr/local/bin/caddy

RUN apk add --no-cache autoconf openssl-dev g++ make pcre-dev icu-dev zlib-dev libzip-dev git
RUN install-php-extensions gd bcmath intl opcache zip sockets exif
# TODO: look at list at https://learn.getgrav.org/17/basics/requirements#php-requirements including optional modules to improve performance
RUN apk del --purge autoconf g++ make
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add a PHP www-user instead of nobody
RUN addgroup -g ${PGID} www-user && \
  adduser -D -H -u ${PUID} -G www-user www-user && \
  sed -i "s|^user = .*|user = www-user|g" "/usr/local/etc/php-fpm.d/www.conf" && \
  sed -i "s|^group = .*|group = www-user|g" "/usr/local/etc/php-fpm.d/www.conf"

ADD https://github.com/getgrav/grav/archive/master.zip /grav/grav.zip
WORKDIR /var/www
RUN ["unzip", "/grav/grav.zip"]

WORKDIR /var/www/grav-master

RUN composer update
RUN composer install --no-dev -o
RUN bin/grav install

EXPOSE 80 443 2015

COPY Caddyfile /etc/Caddyfile
RUN mkdir /tmp/extras
COPY extras /tmp/extras/
COPY init /grav/

RUN caddy -validate

WORKDIR /var/www/grav
ENTRYPOINT ["/bin/sh", "/grav/init-grav"]
