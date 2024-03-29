# v0.2.0
## 02-04-2022

1. [](#new)
    * Initial image release on Github Container Registry (ghcr.io)

# v0.2.1
## 06-05-2022

1. [](#improved)
    * add exif library PHP extension, needed for some Grav image manipulation functions

# v0.2.2
## 05-08-2022

# v0.2.3
## 26-02-2023

1. [](#bugfix)
    * leave .git directory alone when setting Grav file permissions

# v0.2.4
## 28-08-2023

1. [](#bugfix)
    * handle filenames with spaces when setting Grav file permissions ([#10](https://github.com/hughbris/grav-daddy/issues/10))
2. [](#new)
    * add and document `$base_image` build parameter, makes managing multiple base images and swapping in custom ones much simpler (4833540)
3. [](#new)
    * support new $ROBOTS_DISALLOW value to ward off only AI bots via published `robots.txt` ([#11](https://github.com/hughbris/grav-daddy/issues/11))
4. [](#bugfix)
    * runtime environment variables PUID and GUID should now work as expected (fb4a235)
5. [](#improved)
    * rename and redirect project ([#5](https://github.com/hughbris/grav-daddy/issues/5))

# v0.2.4.1
## 03-09-2023

1. [](#improved)
    * default `$base_image` value is `php:8.2-fpm-alpine` to align with [changes to default published images](https://github.com/hughbris/cadaver/discussions/8)
