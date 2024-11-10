# Building the docker image

If you need to build the image locally, maybe for your own special flavour, first clone this repo.

## Basic build-it-yourself

In the repo directory, use this command to build your image. Use whatever target image name you prefer.

```sh
$ docker build -t local/my-organic-cadaver .
```

If you don't want cached copies of the layers in the target image you are building, you can override `docker build`'s default image layer caching behaviour with this intuitive incantation:

```sh
$ docker build --no-cache --pull -t local/my-organic-cadaver .
```
(invaluable guidance surfaced by and sourced from [user @m-dk on stackoverflow.com](https://stackoverflow.com/a/58115741))

> This will use more bandwidth and may *not* be what you want this time.

## Adding in custom build options

| Option | Default | Function |
:------- | :------ | :-------
| `php_ver` | _8.3_ | [PHP version](#php-version) |
| `base_image` | _php:`php_ver`-fpm-alpine_ | [PHP base image](#php-base-image) |
| `Grav_tag` | _master_ | [Grav release or branch](#grav-release-or-branch) |
| `composer_args` | _--no-dev_ | [Composer arguments](#composer-arguments) |
| `php_ini` | _production_ | [php.ini preset profile](#phpini-preset-profile) |

### PHP version

This is a simple shorthand to change the PHP image. Setting this will assume you are simply using the official PHP-FPM Alpine Linux base docker image.

```sh
$ docker build --build-arg --build-arg php_ver=7.4 -t local/my-old-cadaver:php7.4 .
```

> This setting is ignored if you also pass the build argument `base_image`. Use that instead if you want to use a community image.

### PHP base image

You can change the *PHP base image* using the build-time argument `base_image`, e.g.

```sh
$ docker build --build-arg base_image=php:7.4-fpm-bullseye -t local/my-special-cadaver:php7.4 .
```

> Setting `base_image` overrides any `php_ver` value you pass into your build.

> The default `base_image` value is derived from the value of `php_ver`, which has a default value of _8.3_. The default _8.3_ will effectively set `base_image` to _php:8.3-fpm-alpine_.

### Grav release or branch

Let's say you want to try out a new beta or revert to a specific Grav version. Pass in the `Grav_tag` argument when you build the image, e.g.:

```sh
$ docker build --build-arg Grav_tag=1.7.46 -t local/my-niche-cadaver:grav1.7.46 .
```

The default is _master_, which is the branch of the latest official Grav release.

### Composer arguments

A major stage of Grav's installation runs PHP composer. You can pass custom composer flags (arguments) using the `composer_args` docker build parameter.

By default `composer_args` is _--no-dev_, which is suited for productions systems. Therefore the default composer command run by the build script is:

```sh
composer install --no-dev -o
```

(_-o_ is always added and is shorthand for _--optimize-autoloader_)

If you just want the _require-dev_ packages (which the default _--no-dev_ flag disables) because you are making an image for a development server, you'll either need to set the `composer_args` flag blank:

```sh
$ docker build --build-arg composer_args= -t local/my-custom-cadaver:dev .
```

… or pass the redundant _--dev_ value if you're not into the whole brevity thing:

```sh
$ docker build --build-arg composer_args=--dev -t local/my-custom-cadaver:dev .
```

### `php.ini` preset profile

PHP often comes bundled with a couple of bogstandard `php.ini` files to get you started that serve pretty well. There should be at least one for _development_ (`php.ini-development`) and one for _production_ (`php.ini-production`) (the default).

If you want to use the _development_ ini file, build with the `php_ini` argument:

```sh
$ docker build --build-arg php_ini=development -t local/my-playground-cadaver:dev .
```

> I expect if you want your own custom `php.ini`, you could always bind mount `/usr/local/etc/php/php.ini` to your handcrafted ini file on your docker host.