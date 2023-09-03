# Cadaver

Run Grav CMS under Caddy webserver in a docker container.

## Usage

### Sourcing the docker image

This image is currently available from Github's container repository only. It's not hosted on Dockerhub, because I dislike it and also because someone squatted on my username :/

Pull or use the image from its canonical URL:

```sh
$ docker pull ghcr.io/hughbris/cadaver
```

### Building the docker image

If you need to build the image locally, maybe for your own special flavour, first clone this repo.

In the repo directory, use this command to build your image. The image name parameter given after `-t` is not fixed since it's not official, so go ahead and use whatever target image name you prefer.

```sh
$ docker build -t local/my-docker-grav-caddy .
```
There's a good chance that you don't want cached copies of the layers making up the target image you are building. To override `docker build`'s default behaviour of caching image layers, use this intuitive incantation:

```sh
$ docker build --no-cache --pull -t local/my-docker-grav-caddy .
```
(thanks to user @m-dk on stackoverflow.com [for guidance](https://stackoverflow.com/a/58115741); another obscure DX delivered by dockercorp engineers)

> This will use more bandwidth and may *not* be what you want this time.

You can change the *PHP base image* from its default now, using the build-time argument `base_image`, e.g.

```sh
$ docker build --build-arg base_image=php:7.4-fpm-alpine -t local/my-docker-grav-caddy:php7.4 .
```

> [!NOTE]
> As of [`0.2.4.1`](https://github.com/hughbris/cadaver/tree/v0.2.4.1), the default `base_image` value is `php:8.2-fpm-alpine`.

### Using docker-compose

My compose file looks something like this, tweak as needed:

```yaml
version: "3.3"

services:

   grav:
        image: ghcr.io/hughbris/cadaver
        container_name: grav-caddy
        domainname: local
        hostname: grav-caddy
        restart: unless-stopped
        ports:
            - 127.0.0.1:2015:2015
        volumes:
            - /var/data/containers/caddytest/backup:/var/www/grav/backup
            - /var/data/containers/caddytest/logs:/var/www/grav/logs
            - /var/data/containers/caddytest/user:/var/www/grav/user
            - /etc/timezone:/etc/timezone:ro
            - /etc/localtime:/etc/localtime:ro
        environment:
            - PUID=1000
            - PGID=1000
            - ACME_AGREE=true
            # - GRAV_SCHEDULER=true # defaults to false currently
            # - ROBOTS_DISALLOW=true # defaults to false, set true for staging environments etc, see extras/robots.disallow.txt for more discussion; set to "AI_BOTS" to block only AI content harvesters, see extras/robots.ai-bots.txt for details
            # - GRAV_MULTISITE=dir # yet to be implemented
```

## Caveats

Cron and Grav's scheduler are enabled using the `GRAV_SCHEDULER` environment setting. I'm sensing from my research that cron within service containers is unreliable and not recommended / best practice.

## Credits

I started this project trying to marry concepts and techniques found in [dsavell/docker-grav](https://github.com/dsavell/docker-grav) and [seffyroff/caddy-grav-alpine](https://github.com/seffyroff/caddy-grav-alpine).
