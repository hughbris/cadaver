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

#### Runtime environment variables

##### `LOG_LEVEL`

Specify a logging level from `0` to `10` for the container's _startup script_ during container startup. Default is `8`, which will log everything except debugging messages.

> Note that these log levels only apply to the container's startup script, which initialises the Grav environment. Logging from the webserver and any other services are not managed by this setting. A level of `0` will still show container logs.

Level thresholds for log entry types are:

Showing          | Requires at least
---------------- | :---------------:
Errors           | 1
Warnings         | 3
Actions          | 5
Success          | 6
Info _(default)_ | 8
Debug            | 10

##### `ROBOTS_DISALLOW`

Grav websites, including those created using Cadaver, serve a default [`robots.txt`](https://en.wikipedia.org/wiki/Robots_exclusion_standard) file at _/robots.txt_. The `ROBOTS_DISALLOW` variable allows you to serve some rudimentary preset variations of _/robots.txt_.

> You don't need to use this variable, it's a shortcut to some common options. You can also:
> * create a completely custom `robots.txt` on your host and use a bind mount to mount it in your docker container; _or_
> * [set up a custom `robots.txt` file completely within Grav's _/user_ directory, and for specific environments](https://learn.getgrav.org/17/cookbook/general-recipes#display-different-robots-txt-contents-for-different-environments).

**`ROBOTS_DISALLOW` values:**

* **`false`** (default)**:** use the `robots.txt` file bundled with Grav
* **`true`:** use a `robots.txt` file requesting web crawlers _not_ to index your site. Deploy this to any internet accessible environments (e.g. staging) where you have no other protection in place (like HTTP Basic authentication).
* **`AI_BOTS`:** use the standard permissive `robots.txt` file but block some AI content harvesters.

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

Cron and Grav's scheduler are enabled using the `GRAV_SCHEDULER` environment setting. I'm sensing from my research that cron within service containers is unreliable and not recommended / best practice.

## Credits

I started this project trying to marry concepts and techniques found in [dsavell/docker-grav](https://github.com/dsavell/docker-grav) and [seffyroff/caddy-grav-alpine](https://github.com/seffyroff/caddy-grav-alpine).

Fancy ASCII log splash created using [FIGlet](http://www.figlet.org).
