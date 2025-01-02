# Cadaver

## Creating a Grav development environment container

Cadaver is designed by default to be suitable for production server deployment. It's also one of the project's goals to allow you to create containers suitable for local development, with all the tooling and configuration options you might want for that.

From Cadaver 0.2.7, there is a [pre-built `:developer` image/package](https://github.com/hughbris/cadaver/pkgs/container/cadaver/330205655?tag=developer) for this purpose, but you'll still need to set up your container to make use of the development tools and settings. You can also create your own custom development build, of course.

### Building a custom development image

All [build arguments](BUILDING.md#adding-in-custom-build-options) can potentially come into play when creating a development build image. However the `php_ver`, `base_image`, and `Grav_tag` arguments are really for playing with different software stacks, and you probably want your development build stack to mimic your production environment.

`composer_args` allows you to set how your `composer install` is executed when building your image. Of the [many composer flags or aguments available](https://getcomposer.org/doc/03-cli.md#install-i), only a handful are likely to be useful for development builds.

> The pre-packaged [`:developer` image](https://github.com/hughbris/cadaver/pkgs/container/cadaver/330205655?tag=developer) is built using `--build-arg composer_args="--dev -o"`, which installs additional packages specified by composer package creators as required for development stacks.

You may enjoy improved build times by removing the `-o` argument, but Docker's build caching is likely to lessen that benefit.

`php_ini` allows you to switch between _development_ and _production_ ini files that come pre-packaged with the base image. Only these two values will produce valid configurations. If you want to customise your PHP configuration, the simplest technique is to bind mount a `.user.ini` file on the host, as described below.

> The pre-packaged [`:developer` image](https://github.com/hughbris/cadaver/pkgs/container/cadaver/330205655?tag=developer) is built using `--build-arg php_ini=development`.

With `extra_php_extensions`, you can install PHP modules for a development environment. The only one tested to this point, and installed in the `:developer` image tag, is _xdebug_. Further modules may be added by request or as proven useful.

> The pre-packaged [`:developer` image](https://github.com/hughbris/cadaver/pkgs/container/cadaver/330205655?tag=developer) is built using `--build-arg extra_php_extensions=xdebug`.

### Additional mount points

#### Customise PHP settings

You may want to add or override [any of the settings](https://www.php.net/manual/en/ini.list.php) provided in the pre-built _development_ `php.ini` file (symlinked to `php.ini-development`) (or even the _production_ one). The best way to do this is to provide a [`.user.ini` file](https://www.php.net/manual/en/configuration.file.per-user.php) in the same container directory which contains override settings.

For example, I find that Grav and other modules and plugins often generate PHP deprecation warnings on the pages rendered. This is caused by a line in `php.ini-development`:

```ini
error_reporting = E_ALL
```
Since I'm not developing this PHP code, I generally don't touch it and don't need to see these warnings. So for development, I created a file called `_.user.ini` (you can use any name) and put this inside it:

```ini
error_reporting = E_ALL & ~E_DEPRECATED
```
Then I just need to (bind) mount it so that it is available inside my development containers. The additional mount point is:

```yaml
            - type: bind
              source: /local/path/to/_.user.ini # ADAPT THIS!
              target: /usr/local/etc/php/.user.ini
              read_only: true
```

#### View PHP and Xdebug settings

You might find it useful in development containers to see the output of [`phpinfo()`](https://www.php.net/manual/en/function.phpinfo.php) and [`xdebug_info()`](https://xdebug.org/docs/develop#xdebug_info) if you installed Xdebug.

The easiest way to make this available for your development containers is to create a PHP file on your host and bind mount it. I have a file called `_info.php` with this code:

```php
<ul>
    <li><a href="#php">phpinfo</a></li>
    <li><a href="#xdb">XDebug info</a></li>
</ul>
<div id="php">
    <?php phpinfo(); ?>
</div>
<div id="xdb">
    <?php xdebug_info(); ?>
</div>
```
I add the mount point to my docker-compose file with:

```yaml
            - type: bind
              source: /local/path/to/_info.php # ADAPT THIS!
              target: /var/www/grav/info.php
              read_only: true
```
Then you can load this by visiting the path `/info.php` (https://_yourhostname_/info.php) in your browser.

#### Configure Xdebug options

It's likely that if you are using Xdebug, you'll want to hack its settings. You can achieve this, for [some options only](https://xdebug.org/docs/all_settings#XDEBUG_CONFIG), by [setting container environment variables](#development-container-environment-variable-settings), but a bind mounted Xdebug configuration file is simple and most flexible.

An example Xdebug configuration file I use is:

```ini
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=xdebug://gateway
xdebug.discover_client_host=off
xdebug.idekey=vsc ; matches the key I configure in VSCode IDE extension
xdebug.output_dir=/var/tmp/xdebug
xdebug.log=/var/tmp/xdebug/xdebug-grav.log
```
> This example only enables Xdebug's [step debugging](https://xdebug.org/docs/step_debug) and you may want to add more using `xdebug.mode`.

All that's left to do now is to save this file on your host system and create a bind mount to `/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini`:

```yaml
            - type: bind
              source: /local/path/to/_xdebug.ini # ADAPT THIS!
              target: /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
              read_only: true
```

#### Persist Xdebug's output

**This is an optional step** in case you want your Xdebug output to persist between container restarts. If you don't need that, then you won't need this bind mount.

Find a directory location on your host where you want your debugging output to live. You can get Docker to create this when you bring up the container or create it first with `mkdir`.

> If you use `mkdir`, be sure to change its ownership to the container's _www-user_ user ID or you'll encounter errors.

This docker-compose snippet gets Docker to create your directory if it doesn't exist. To change its ownership from _root_, there's another block to add which we will outline.

```yaml
            - type: bind
              source: /local/path/to/debug # ADAPT THIS!
              target: /var/tmp/xdebug
              bind:
                  create_host_path: true # this will create directory with root permissions
```
Now at the top level under your `grav` container service, add this [`post-start` block](https://docs.docker.com/reference/compose-file/services/#post_start) to make sure your container directory has the right ownership:

```yaml
services:

    grav:
        …
        post_start:
            - command: chown -R www-user:www-user /var/tmp/xdebug
              user: root
        …
```
That `chown` command will run with _root_ permissions every time the container starts. It's probably not necessary after the first time but it doesn't hurt either.

### Development container environment variable settings

You probably won't need to set any special container environment variables for a development environment, but you could consider these ones.

You could reduce [`FILE_SIZE_LIMIT`](ENVIRONMENT.md#file_size_limit) if you determine that the default value of 8192 is causing performance issues.

You may want to set [`ROBOTS_DISALLOW`](ENVIRONMENT.md#robots_disallow) to _true_ if you believe your development environment is not adequately firewalled.

You could set your [container startup `LOG_LEVEL`](ENVIRONMENT.md#log_level) all the way to 10 to include debug messages.

If you want to set or override any Xdebug options, it could be useful to do this on a per-container basis using environment variables. For example, you might want to change which Xdebug features are enabled using the [XDEBUG_MODE environment variable](https://xdebug.org/docs/all_settings#mode):

```yaml
        environment:
            …
            XDEBUG_MODE: debug,develop,trace
```

You can also use [XDEBUG_CONFIG](https://xdebug.org/docs/all_settings#XDEBUG_CONFIG) to set a selection of Xdebug options, for example:

```yaml
        environment:
            …
            XDEBUG_CONFIG: log=/tmp/xdebug/xdebug-grav.log output_dir=/tmp/xdebug
```

## Connecting your development container and your host Xdebug tools

Something unintuitive about the way Xdebug works that I didn't see mentioned enough online, is that Xdebug tools run as a service and your Grav server container connects to them (as a client).

There are plenty of guides for setting up various Xdebug tools, but this key assumption is rarely spelled out.

In tools like VSCode's "PHP Debug" (_xdebug.php-debug_), you need to first make sure they are listening for Xdebug connections from your container, typically on port 9003. With your container running, a good way to check the connection is using the `xdebug_info()` function (see the [recommended setup above](#view-php-and-xdebug-settings)).

A common problem seen in `xdebug_info()` is that Xdebug cannot connect at the container's address and Xdebug port. This is usually a host firewall problem and you simply need to allow your container(s) to connect to your host on the Xdebug port (normally 9003/tcp).
