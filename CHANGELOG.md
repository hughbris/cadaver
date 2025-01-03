# v0.2.7
## 02-01-2025

1. [](#new)
    * `FILE_SIZE_LIMIT` (ulimit) runtime environment var defaulting to 8192 for production servers (4509f81)
    * `extra_php_extensions` build argument (4895cb2), allowing additional PHP extensions like _xdebug_ ([#4](https://github.com/hughbris/cadaver/issues/4))
    * document development builds and setup (92a1b25)

2. [](#improved)
    * more [opencontainers annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md) ([#20](https://github.com/hughbris/cadaver/issues/20); a59f348)
    * `-o` is no longer a hardcoded composer flag, added to `composer_args` default (792ef7a)
    * tidied up, updated docs and corrected links
    * Dockerfile command ordering

3. [](#bugfix)
    * compose was not installing correctly when executed before grav/install, switched command order in Dockerfile (309b8fe)

# v0.2.6
## 09-12-2024

1. [](#new)
    * add init script log levels variable and new debug log entries (9564980)
    * fancy colourful splash banner in log

2. [](#improved)
    * default PHP minor version is PHP 8.4
    * better, configurable permission setting commands
    * move Grav setup steps to separate shell file and source from init script
    * test and document `GRAV_SCHEDULER` and outline better solutions using dedicated scheduler service containers in the README
    * add mount points synopsis to README

3. [](#bugfix)
    * detecting `logs` and `backup` directories for existing installs no longer throws an error (~ce5490e nope~ → d859101)

# v0.2.5.1
## 21-11-2024

1. [](#new)
    * add shorthand build argument `php_ver` (a2ad3c5)

2. [](#improved)
    * rename init script and path (a90556f)
    * logging

3. [](#bugfix)
    * admit mistake incorporating development commits accidentally released into 0.2.5

# v0.2.5
## 21-11-2024

1. [](#new)
    * add support for Google AI bot disallowing robots directive (bfe5f55)
    * add maintainer LABEL to dockerfile (3fa6d0a)
    * add `Grav_tag` to select custom Grav branches or tags (47f2548)
    * add `composer_args` to allow setting composer flags (f0002c7)
    * add `php_ini` to change active preset PHP profile ini file (eca52c1)

2. [](#improved)
    * change default base image PHP from 8.2 to 8.3; potentially process-breaking (65d6266)
    * don't allow Grav to serve Grav's README.md file at /README.md (99d57b1)
    * docs improvements (4d140e4 + 4ce96d7)
    * clone Grav repo rather than pulling and unzipping (47f2548 / e3e2d1d)

# v0.2.4.1
## 03-09-2023

1. [](#improved)
    * default `$base_image` value is `php:8.2-fpm-alpine` to align with [changes to default published images](https://github.com/hughbris/cadaver/discussions/8)

# v0.2.4
## 28-08-2023

1. [](#new)
    * add and document `$base_image` build parameter, makes managing multiple base images and swapping in custom ones much simpler (4833540)
    * support new $ROBOTS_DISALLOW value to ward off only AI bots via published `robots.txt` ([#11](https://github.com/hughbris/cadaver/issues/11))

2. [](#improved)
    * rename and redirect project ([#5](https://github.com/hughbris/cadaver/issues/5))

3. [](#bugfix)
    * handle filenames with spaces when setting Grav file permissions ([#10](https://github.com/hughbris/cadaver/issues/10))
    * runtime environment variables PUID and GUID should now work as expected (fb4a235)

# v0.2.3
## 26-02-2023

1. [](#bugfix)
    * leave .git directory alone when setting Grav file permissions

# v0.2.2
## 05-08-2022

# v0.2.1
## 06-05-2022

1. [](#improved)
    * add exif library PHP extension, needed for some Grav image manipulation functions

# v0.2.0
## 02-04-2022

1. [](#new)
    * Initial image release on Github Container Registry (ghcr.io)
