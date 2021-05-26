FROM abiosoft/caddy:php-no-stats

RUN apk update && \
    apk add --no-cache tzdata

ADD https://github.com/getgrav/grav/archive/master.zip /grav/grav.zip
WORKDIR /var/www
RUN ["unzip", "/grav/grav.zip"]

WORKDIR /var/www/grav-master
RUN composer install --no-dev -o
RUN bin/grav install

EXPOSE 80 443 2015

COPY Caddyfile /etc/Caddyfile
RUN mkdir /tmp/extras
COPY extras /tmp/extras/
COPY init /grav/

WORKDIR /var/www/grav
ENTRYPOINT ["/bin/sh", "/grav/init-grav"]
