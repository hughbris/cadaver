# Grav daddy

Run Grav CMS under Caddy webserver in a docker container.

## Usage

### Sourcing the docker image

This image is currently available from Github's container repository only. It's not hosted on Dockerhub, because I dislike it and also because someone squatted on my username :/

Pull or use the image from its canonical URL:

```sh
$ docker pull ghcr.io/hughbris/grav-daddy
```

### Building the docker image

If you need to build the image locally, maybe for your own special flavour, first clone this repo.

In the repo directory, use this command to build your image. The image name parameter given after `-t` is not fixed since it's not official, so go ahead and use whatever image name you prefer.

```sh
$ docker build -t local/my-docker-grav-caddy .
```

### Using docker-compose

My compose file looks something like this, tweak as needed:

```yaml
version: "3.3"

services:

   grav:
        image: ghcr.io/hughbris/grav-daddy
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
            # - ROBOTS_DISALLOW=true # defaults to false, set true for staging envornments etc, see extras/robots.disallow.txt for more discussion
            # - GRAV_MULTISITE=dir # yet to be implemented
```

## Caveats

Cron and Grav's scheduler are enabled using the `GRAV_SCHEDULER` environment setting. I'm sensing from my research that cron within service containers is unreliable and not recommended / best practice.

## Credits

I started this project trying to marry concepts and techniques found in [dsavell/docker-grav](https://github.com/dsavell/docker-grav) and [seffyroff/caddy-grav-alpine](https://github.com/seffyroff/caddy-grav-alpine).
