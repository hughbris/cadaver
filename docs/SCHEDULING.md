# Cadaver

* Usage
  * Running containers
    * Runtime environment variables

## Running scheduler service containers to trigger Grav's Scheduler

> It's easy to configure your Cadaver containers to run the scheduler using service containers and magic [Docker labels](https://docs.docker.com/reference/compose-file/services/#labels). We will describe how to set this up.

[Ofelia](https://github.com/mcuadros/ofelia) and [deck-chores](https://github.com/funkyfuture/deck-chores) are two container images which provide a scheduler service that you can configure to run Grav's scheduler.

Ofelia and deck-chores are pretty close in setup and features. Both solutions require these steps:

1. [**Check**](#check) that Cadaver's included scheduler is off.
1. [**Add formatted labels**](#label) to Cadaver containers.
1. [**Run the scheduler** service container](#service). We do this last so that the service picks up the container labels, as it will not discover changes to these labels without a restart.

### Feature support and comparison

* Ofelia allows scheduling to the **precision** of seconds, allowing you to stagger your host server's load over the different parts of the minute when your containers' running Grav schedulers fire;
* deck-chores allows you to set **execution timezones** globally and per container; it's not clear if Ofelia supports different container timezones natively, not at all, or supports configuring per container;
* Neither have straighforward **log redirection** support/documentation;
* Neither support dynamic **schedule reloading** when running container labels are changed.

> If you update Cadaver container labels, you need to restart your scheduler container service with something like `docker-compose up -d --force-recreate` so that the service detects and loads your modifications.

### Steps

<div id="check">

First, ensure that `GRAV_SCHEDULER` is not true in your container so that we're not running Cadaver's included scheduler.

</div>

<div id="label">

Then you just need to add some labels to your Cadaver container's docker-compose file (or other):

```yaml
    environment:
      # …
      GRAV_SCHEDULER: false # this is the default, just make sure it's not set true
    labels:
      # …

      # *** This example shows labels for each solution. Choose one for the solution you are using. Using both sets of labels won't cause issues unless you run both scheduler service containers concurrently.

      # Ofelia:
      ofelia.enabled: true
      ofelia.job-exec.grav-scheduler.command: sh -c "/var/www/grav/bin/grav scheduler 1>> /dev/null 2>&1" # this logs errors to the Ofelia container, yet to figure out how to redirect those to Cadaver containers
      ofelia.job-exec.grav-scheduler.schedule: "@every 1m" # or …
      # ofelia.job-exec.grav-scheduler.schedule: "30 * * * * *" # this schedule runs at 30 seconds past each minute rather than in the first second
      ofelia.job-exec.grav-scheduler.user: www-user

      # deck-chores:
      deck-chores.grav-scheduler.command: sh -c "/var/www/grav/bin/grav scheduler 1>> /dev/null 2>&1" # this logs errors to the deck-chores container, yet to figure out how to redirect those to Cadaver containers
      deck-chores.grav-scheduler.interval: every minute
      deck-chores.grav-scheduler.user: www-user
      # deck-chores.grav-scheduler.env.timezone: Pacific/Auckland # to override the scheduling TIMEZONE of the deck-chores container if necessary
```

</div>

<div id="service">

Then create a docker-compose file for your scheduler container.

**Ofelia example:**

```yaml
name: ofelia_example

services:
  ofelia:
    container_name: ofelia-example
    image: mcuadros/ofelia # if there's a stable image tag, I don't know it
    restart: unless-stopped
    command: daemon --docker # you must specify this if you want ofelia to use your container docker labels (by default it supports an ini file configuration option)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

**deck-chores example:**

```yaml
name: deck-chores_example

services:
  officer:
    container_name: deck-chores-example
    image: ghcr.io/funkyfuture/deck-chores:1
    restart: unless-stopped
    # environment: # this will be the default timezone for your container jobs
    #   TIMEZONE: # uses UTC if not specified
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # maybe bind mount a volume for persistent logs here, since I haven't been able to redirect these to the calling container yet
```

Then `docker compose up -d` to get that started. When restarting after modifying your Cadaver container's labels (and restarting those containers first!), you may need to add `--force-recreate` to reload those reliably.

</div>
