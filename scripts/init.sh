#!/bin/sh
source "/grav/helpers.sh"

LogInfo "Init script starting"

# Setup Grav

export GRAV_ROOT=/var/www/grav
export GRAV_TEMP=/var/www/grav-src

cd $GRAV_TEMP

if [[ -e $GRAV_ROOT/backup/* || -e $GRAV_ROOT/backup/.gitkeep ]]; then
  LogInfo "Using existing backup directory"
else
  LogAction "Fresh install, moving backup"
  mv $GRAV_TEMP/backup $GRAV_ROOT/ \
    && LogSuccess "Moved backup" \
    || LogError "Could not move backup"
fi

if [[ -e $GRAV_ROOT/logs/* || -e $GRAV_ROOT/logs/.gitkeep ]]; then
  LogInfo "Using existing logs directory"
else
  LogAction "Fresh install, moving logs"
  mv $GRAV_TEMP/logs $GRAV_ROOT/ \
     && LogSuccess "Moved logs" \
    || LogError "Could not move logs"
fi

if [[ -e $GRAV_ROOT/user/config/site.yaml ]]; then
  LogInfo "Using existing user directory"
else
  LogAction "Fresh install, moving user directories"
  mkdir $GRAV_ROOT/user
  mv $GRAV_TEMP/user/* $GRAV_ROOT/user/ \
    && LogSuccess "Moved user directories" \
    || LogError "Could not move all user directories"
fi

LogAction "Moving Grav core"
find ./* -type d \( ! -regex '^\./\(user\|backup\|logs\)$' \) -maxdepth 0 -exec mv '{}' $GRAV_ROOT/ \;
find ./ -type d -name ".?*" -maxdepth 1 -exec mv '{}' $GRAV_ROOT/ \; # because above match expression does not include hidden dirs, .github etc
find . -type f -maxdepth 1 -exec mv {} $GRAV_ROOT/ \;

# TODO
# check for supported GRAV_MULTISITE setting
# echo "Checking for multisite environment .."
# if [[ ! -z "${GRAV_MULTISITE}" && "$GRAV_MULTISITE" == "subdirectory" ]]; then
#   echo "Copying multisite setup.php .."
#   cp /tmp/env/setup_subdirectory.php $GRAV_ROOT/setup.php
#   mkdir -p $GRAV_ROOT/user/sites
# fi

# Copy robots.txt file with disallow everything directive if set
ROBOTS_DISALLOW=${ROBOTS_DISALLOW:-"false"}
if [[ $ROBOTS_DISALLOW == "AI_BOTS" ]]; then
  LogAction "Discouraging AI bots only with robots.txt"
  cat $GRAV_ROOT/robots.txt >> /tmp/extras/robots.ai-bots.txt \
    && cp -f /tmp/extras/robots.ai-bots.txt $GRAV_ROOT/robots.txt \
    || LogError "Could not create custom robots.txt"
elif [[ $ROBOTS_DISALLOW == "true" ]]; then
  LogAction "Copying discouraging robots.txt"
  cp -f /tmp/extras/robots.disallow.txt $GRAV_ROOT/robots.txt \
    || LogError "Could not create restrictive robots.txt"
fi

# Clean up
LogAction "Cleaning up working files"
rm -Rf $GRAV_TEMP
rm -Rf /tmp/extras

# Set Permissions, based on https://learn.getgrav.org/17/troubleshooting/permissions#different-accounts-fix-permissions-manually
# NB: using find's -exec flag syntax makes serving fail for some reason, probably a flavour thing
LogAction "Setting permissions with chmod (+ chown, umask)"
cd $GRAV_ROOT

find . $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 -r chown www-user:www-user
find . -type f $PERMISSIONS_GLOBAL $PERMISSIONS_FILES -print0 | xargs -0 -n1 chmod 664
find ./bin -type f $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 chmod 775
find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod 775
find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod +s
umask 0002

# set and start cron
GRAV_SCHEDULER=${GRAV_SCHEDULER:-false}
# there are a few reasons you might not want the scheduler on:
#   - not needed for any custom jobs in a dev/test environment,
#   - it's not reliable in a container (so it's been said, this is also why this setting defaults to false currently),
#   - you want to run cron from outside the container (on host or dedicated container, as is apparently best practice).
if [[ $GRAV_SCHEDULER == "true" ]]; then
  LogAction "Adding grav scheduler to caddy user's crontab"
  touch /var/spool/cron/crontabs/www-user && chown www-user /var/spool/cron/crontabs/www-user
  (crontab -l; echo "* * * * * cd /var/www/grav;bin/grav scheduler 1>> /dev/null 2>&1") | crontab -u www-user - && \
    crond -l 0 -L /var/log/cron.log
else
  LogInfo "Did not set up Grav scheduler"
fi

LogSuccess "Init steps completed"
LogAction "Starting caddy"
/usr/local/bin/caddy --conf /etc/Caddyfile --log stdout --agree=$ACME_AGREE # TODO: check $ACME_AGREE is being used
