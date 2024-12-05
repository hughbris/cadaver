#!/bin/sh
source "/grav/helpers.sh"
source "/grav/setup.sh"

export LOG_LEVEL=${LOG_LEVEL:-8}

LogInfo "Init script starting"

ExecDestroy() {
  LogDebug "Execute and destroy: $1"
  $1 && unset -f $1
}

# Setup Grav
export GRAV_ROOT=/var/www/grav
export GRAV_TEMP=/var/www/grav-src

cd $GRAV_TEMP

ExecDestroy GravSetupPersistent
ExecDestroy GravSetupEphemeral

# TODO
# check for supported GRAV_MULTISITE setting
# echo "Checking for multisite environment .."
# if [[ ! -z "${GRAV_MULTISITE}" && "$GRAV_MULTISITE" == "subdirectory" ]]; then
#   echo "Copying multisite setup.php .."
#   cp /tmp/env/setup_subdirectory.php $GRAV_ROOT/setup.php
#   mkdir -p $GRAV_ROOT/user/sites
# fi

ExecDestroy GravSetupRobotsTxt

# Clean up
LogAction "Cleaning up working files"
cd $GRAV_ROOT
rm -Rf $GRAV_TEMP
rm -Rf /tmp/extras

GravSetPermissions

ExecDestroy InitGravScheduler

LogSuccess "Init steps completed"
LogAction "Starting caddy"
/usr/local/bin/caddy --conf /etc/Caddyfile --log stdout --agree=$ACME_AGREE # TODO: check $ACME_AGREE is being used
