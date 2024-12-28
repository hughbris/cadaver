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

You can use one of the [packaged images already built](https://github.com/hughbris/cadaver/pkgs/container/cadaver) or [build your own](docs/BUILDING.md) if you want to deploy some custom options.

### Running containers

#### Mount points

Container path             | Mount usage
-------------------------- | ---------------
`/var/www/grav/backup`     | Mount this if you want to keep Grav backups. Bear in mind that Grav's scheduler may not run if cron is not running in your container. Also bear in mind that a collection of Grav backups, especially created on a schedule, can get very large.
`/var/www/grav/logs`       | Mount this to persist Grav's logs. You may not care about this on a development or temporary installment.
`/var/www/grav/user`       | Be sure to bind mount this to your host if you want your website to persist between reboots. You almost always want to mount this.
`/etc/timezone`            | Standard best practice for many container images to inherit the host's timezone, _bind mount read-only_.
`/etc/localtime`           | Standard best practice for many container images, _mount read-only_.
`/var/www/grav/robots.txt` | You can bind mount this read-only to a fully custom `robots.txt` file on your host. If your requirements are standard, you can also use the[`ROBOTS_DISALLOW`](docs/ENVIRONMENT.md#ROBOTS_DISALLOW) environment variable for common preset options. You can also set up a custom _/robots.txt_ within Grav's user directory using the [recipe on Grav Learn](https://learn.getgrav.org/17/cookbook/general-recipes#display-different-robots-txt-contents-for-different-environments).

#### Runtime environment variables

There is a selection of [environment variables](https://docs.docker.com/get-started/docker-concepts/running-containers/overriding-container-defaults/#setting-environment-variables) you can pass a Cadaver container when you start it which affect its behaviour:

Variable           | Default    | Description
-----------------: | :--------------- | :---------------
[`LOG_LEVEL`](docs/ENVIRONMENT.md#log_level)             | 8       | Set how verbosely the startup script outputs log messages
[`ROBOTS_DISALLOW`](docs/ENVIRONMENT.md#robots_disallow) | _false_ | Control which indexing bots your container's website encourages
[`GRAV_SCHEDULER`](docs/ENVIRONMENT.md#grav_scheduler)   | _false_ | Toggle your container's built-in scheduling process
[`FILE_SIZE_LIMIT`](docs/ENVIRONMENT.md#file_size_limit) | 8192    | Change the container's file descriptor limit (`ulimit`)

#### Example docker-compose

My compose file looks something like this, tweak as needed:

```yaml
version: "3.3"

services:

   grav:
        image: ghcr.io/hughbris/cadaver
        container_name: grav-caddy
        domainname: localhost
        hostname: cadavertest
        restart: unless-stopped
        ports:
            - target: 2015
              host_ip: 127.0.0.1
              published: 666
            # - 127.0.0.1:666:2015 if you prefer stupid shorthands
        volumes:
            # there's a traditional short, confusing shorthand for volumes too
            - type: bind
              source: /var/data/containers/cadavertest/backup
              target: /var/www/grav/backup
            - type: bind
              source: /var/data/containers/cadavertest/logs
              target: /var/www/grav/logs
            - type: bind
              source: /var/data/containers/cadavertest/user
              target: /var/www/grav/user
            - type: bind
              source: /etc/timezone
              target: /etc/timezone
              read_only: true
            - type: bind
              source: /etc/localtime
              target: /etc/localtime
              read_only: true
        environment:
            - PUID=1000
            - PGID=1000
            - ACME_AGREE=true
            # - GRAV_SCHEDULER=true # defaults to false currently
            # - ROBOTS_DISALLOW=true
            # - LOG_LEVEL=10
            # - FILE_SIZE_LIMIT=8192

            # ** PERMISSIONS_* variables all default to empty string **
            # - PERMISSIONS_GLOBAL=-xdev # global find arguments for permission setting
            # - PERMISSIONS_FILES='! -path "*/.git/*"' # find arguments for files permission setting
            # - PERMISSIONS_DIRS='! -path "*/.git" ! -path "*/.git/*"' # find arguments for directories permission setting
            # ** the last example value produces a find command like:
            # **  find . -type d -xdev ! -path "*/.git" ! -path "*/.git/*" -print0

            # - GRAV_MULTISITE=dir # yet to be implemented
```

This serves the site at http://127.0.0.1:666. The first test I usually perform is `curl -I 127.0.0.1:666` and look for `200 OK`.

## Caveats

Cron and Grav's scheduler are enabled using the `GRAV_SCHEDULER` environment setting. Support for running `cron` in the service container using this variable [may be removed in future](docs/ENVIRONMENT.md#robots_disallow).

## Credits

I started this project trying to marry concepts and techniques found in [dsavell/docker-grav](https://github.com/dsavell/docker-grav) and [seffyroff/caddy-grav-alpine](https://github.com/seffyroff/caddy-grav-alpine).

Fancy ASCII log splash created using [FIGlet](http://www.figlet.org).
