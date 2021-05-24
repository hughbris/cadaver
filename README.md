# Grav daddy

Run Grav CMS under Caddy webserver in a docker container.

## Usage

### Building the docker image

This image is not currently hosted on Dockerhub (since I dislike it and also someone squatted on my username :/) or other repos, so you need to build the image locally.

In the repo directory, I use this command to build my image. The image name parameter given after `-t` is not fixed since it's not official, so go ahead and use whatever image name you prefer.

```sh
$ docker build -t hughbris/docker-grav-caddy .
```

### Using docker-compose

My compose file looks something like this, tweak as needed:

```yaml
version: "3.3"

services:

   grav:
        image: hughbris/docker-grav-caddy
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
            # - GRAV_MULTISITE=dir # yet to be implemented

networks:
    default:
        name: grav-caddy-net
```

## Caveats

Cron and Grav's scheduler are enabled using the `GRAV_SCHEDULER` environment setting. I'm sensing from my research that cron within service containers is unreliable and not recommended / best practice.

## Credits

I started this project trying to marry concepts and techniques found in [dsavell/docker-grav](https://github.com/dsavell/docker-grav) and [seffyroff/caddy-grav-alpine](https://github.com/seffyroff/caddy-grav-alpine).
