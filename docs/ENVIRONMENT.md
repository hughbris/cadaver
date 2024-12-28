# Cadaver

* [Usage](../README.md#usage)
  * [Running containers](../README.md#running-containers)

## Runtime environment variables

You can configure a Cadaver container and affect its behaviour by passing [environment variables](https://docs.docker.com/get-started/docker-concepts/running-containers/overriding-container-defaults/#setting-environment-variables) when you start it.

You can pass environment variables when bringing up Cadaver containers [using command line](https://docs.docker.com/reference/cli/docker/container/run/#env) or [with docker-compose](https://docs.docker.com/reference/compose-file/services/#environment).

> If you are building a custom image for a development environment, be sure to check out the [recommended development environment settings](DEVELOPMENT.md).

### `LOG_LEVEL`

Specify a logging level from `0` to `10` for the container's _startup script_ during container startup. **Default is `8`**, which will log everything except debugging messages.

> Note that these log levels only apply to the container's startup script, which initialises the Grav environment. Logging from the webserver and any other services are not managed by this setting. A level of `0` will still show container logs.

Level thresholds for log entry types are:

Showing          | Requires at least
---------------- | :---------------:
Errors           | 1
Warnings         | 3
Actions          | 5
Success          | 6
Info _(default)_ | 8
Debug messages   | 10

### `ROBOTS_DISALLOW`

Grav websites, including those created using Cadaver, serve a default [`robots.txt`](https://en.wikipedia.org/wiki/Robots_exclusion_standard) file at _/robots.txt_. The `ROBOTS_DISALLOW` variable allows you to serve some rudimentary preset variations of _/robots.txt_.

> You don't need to use this variable, it's a shortcut to some common options. You can also:
> * create a completely custom `robots.txt` on your host and use a bind mount to mount it in your docker container; _or_
> * [set up a custom `robots.txt` file completely within Grav's _/user_ directory, and for specific environments](https://learn.getgrav.org/17/cookbook/general-recipes#display-different-robots-txt-contents-for-different-environments).

#### Recognised values

Value                | Meaning
-------------------- | ---------------
_false_  _(default)_ | Use the `robots.txt` file bundled with Grav.
_true_               | Use a `robots.txt` file requesting web crawlers _not_ to index your site. Deploy this to any internet accessible environments (e.g. staging) where you have no other protection in place (like HTTP Basic authentication).
AI_BOTS              | Use the standard permissive `robots.txt` file but block some AI content harvesters.

### `GRAV_SCHEDULER`

This setting controls setting up and establishing Grav's job scheduler by setting up a `cron` job _inside the container_. Set this to `true` to set up and enable the included scheduler. By default this is `false`/disabled.

> While the in-container cron-based scheduler _works with the current PHP-FPM base image,_ running a cron process within a container providing another service seems antithetical to Docker best practices. You might want to consider another method for enabling Grav's scheduler for this reason, and also because **future versions of Cadaver [may use a different base image](https://github.com/hughbris/cadaver/issues/12) without a `cron` service**. If that happens, the `GRAV_SCHEDULER` variable won't be supported. [Future-proof alternatives are discussed below](#alternative-scheduler-implementations).

There are a few reasons you might want to disable Grav's _included_ scheduler:

* it's not needed, for example:
  * you don't need zipped backups because you're using version control
  * you don't need the built-in cache maintenance jobs because you are in a non-production environment
  * you have no custom jobs set up
* you think it's an anti-pattern and/or unreliable within the service container _(see note above)_
* you want to [run cron from outside the container](SCHEDULING.md) (as is apparently best practice).

#### Alternative scheduler implementations

You can simply run the Grav scheduler in your container **on your host machine**, adding a line like this to your host `crontab`:

```sh
* * * * * docker exec -u www-user cadaver-dev sh -c "/var/www/grav/bin/grav scheduler 1>> /dev/null 2>&1"
```

Instead of messing with the host's `crontab`, you may prefer to **[run a dedicated cron service container](SCHEDULING.md)** like _Ofelia_ or _deck-chores_.

### `FILE_SIZE_LIMIT`

Use this setting to adjust the container's file descriptor limit (`ulimit`). This variable was added for production environments after seeing this warning in the container logs:

    WARNING: File descriptor limit 1024 is too low for production servers. At least 8192 is recommended. Fix with `ulimit -n 8192`

The default value is the recommended 8192 for production servers.

> It's unclear if there are good reasons to reduce this value in other environments, or why the base image uses the low value. You can probably ignore this setting without consequences if you don't understand its impact.
