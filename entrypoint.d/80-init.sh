#!/bin/sh
source /grav/helpers.sh
source /grav/setup.sh

export LOG_LEVEL=${LOG_LEVEL:-8}
ULIMIT_DEFAULT=8192

LogSplash

LogInfo "Init script starting"

# Setup Grav
export GRAV_ROOT=/var/www/grav
export GRAV_TEMP=/var/www/grav-src

cd $GRAV_TEMP

GravSetupPersistent
GravSetupEphemeral

# TODO
# check for supported GRAV_MULTISITE setting
# echo "Checking for multisite environment .."
# if [[ ! -z "${GRAV_MULTISITE}" && "$GRAV_MULTISITE" == "subdirectory" ]]; then
#   echo "Copying multisite setup.php .."
#   cp /tmp/env/setup_subdirectory.php $GRAV_ROOT/setup.php
#   mkdir -p $GRAV_ROOT/user/sites
# fi

GravSetupRobotsTxt

# Clean up
LogAction "Cleaning up working files"
cd $GRAV_ROOT
rm -Rf $GRAV_TEMP
rm -Rf /tmp/extras

GravSetPermissions

InitGravScheduler

if [[ -z "$FILE_SIZE_LIMIT" ]]; then
    LogInfo "Using default file size limit (ulimit) of $ULIMIT_DEFAULT, tweak this with \$FILE_SIZE_LIMIT"
    export FILE_SIZE_LIMIT=$ULIMIT_DEFAULT
fi
LogAction "Setting file size limit (ulimit) to $FILE_SIZE_LIMIT"
ulimit -n $FILE_SIZE_LIMIT

LogSuccess "Init steps completed"
# LogAction "Starting caddy"
# /usr/local/bin/caddy --conf /etc/Caddyfile --log stdout --agree=$ACME_AGREE # TODO: check $ACME_AGREE is being used
