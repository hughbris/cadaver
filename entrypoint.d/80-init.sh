#!/bin/sh
source /grav/helpers.sh
source /grav/setup.sh

export LOG_LEVEL=${LOG_LEVEL:-8}
ULIMIT_DEFAULT=8192
export FILE_SIZE_LIMIT=${FILE_SIZE_LIMIT:-$ULIMIT_DEFAULT}

LogSplash

LogInfo "Init script starting"

# Setup Grav
export GRAV_ROOT=$CADDY_APP_PUBLIC_PATH
export GRAV_TEMP=$FRESHG

LogInfo "Setting up into $GRAV_ROOT from $GRAV_TEMP"

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
rm -Rf $GRAV_TEMP
rm -Rf /tmp/extras

GravSetPermissions

LogAction "Setting file size limit (ulimit) to $FILE_SIZE_LIMIT"
if [[ $FILE_SIZE_LIMIT -eq $ULIMIT_DEFAULT ]]; then
    LogInfo "This is the default file size limit, tweak it with \$FILE_SIZE_LIMIT"
fi
ulimit -n $FILE_SIZE_LIMIT

LogSuccess "Init steps completed"
