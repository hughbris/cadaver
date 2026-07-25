ARG php_ver=8.5
ARG alpine_ver=
ARG base_image=php:${base_image:-${php_ver}-fpm-alpine${alpine_ver}}
FROM $base_image
# credit for important parts of this to https://gist.github.com/Baldinof/8af17f09c7a57aa468e1b6c66d4272a3

ARG Grav_tag=master
ARG composer_args='--no-dev -o'
ARG php_ini=production
ARG extra_php_extensions
ARG network_clone_hack=42

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
ARG PUID="1000"
ARG PGID="1000"

# Let's Encrypt Agreement
# FIXME: hmm, do I need this?
ENV ACME_AGREE="false"

RUN apk update && \
    apk add --no-cache tzdata autoconf openssl-dev g++ make pcre-dev icu-dev git && \
    if [[ $network_clone_hack -ne 0 ]]; then \
      apk add yq; \
    fi

ADD  --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
COPY --from=ghcr.io/composer/docker:latest-bin /composer /usr/bin/composer
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy

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
ADD --chown=www-user:www-user https://github.com/getgrav/grav.git#${Grav_tag} ./grav-src

WORKDIR /var/www/grav-src
USER www-user

RUN <<EOT
  if [[ $network_clone_hack -ne 0 ]]; then
    for i in $(yq '.git.[] | path | .[-1]' < .dependencies); do
      url=$(yq ".git.$i | .url" .dependencies).git
      path=$(yq ".git.$i | .path" .dependencies)
      branch=$(yq ".git.$i | .branch" .dependencies)
      clone_cmd="git clone -b ${branch} -v --depth 1 -- ${url} ./${path}"

      $clone_cmd
      if [[ $? -ne 0 ]]; then
        # github's just shy, try again bro ..
        $clone_cmd
      fi
    done
  fi
EOT

RUN composer install $composer_args
RUN bin/grav install

USER root

RUN if [[ $network_clone_hack -ne 0 ]]; then \
      apk del --purge yq; \
    fi

EXPOSE 80 443 2015

COPY Caddyfile /etc/
COPY extras /tmp/extras
COPY scripts /grav/

RUN caddy validate --config /etc/Caddyfile

# TODO: invoke USER here?? (https://docs.docker.com/reference/dockerfile/#user)
# RUN exec php-fpm -D

# TODO: add a HEALTHCHECK?? (https://docs.docker.com/reference/dockerfile/#healthcheck)

WORKDIR /var/www/grav
ENTRYPOINT ["/bin/sh", "/grav/init.sh"]
