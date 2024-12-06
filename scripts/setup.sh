#!/bin/sh

#
# Grav files setup

GravSetupPersistent() {

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
}

GravSetupEphemeral() {
  cd $GRAV_TEMP
  LogAction "Moving Grav core"

  find ./* -type d \( ! -regex '^\./\(user\|backup\|logs\)$' \) -maxdepth 0 -exec mv '{}' $GRAV_ROOT/ \;
  find ./ -type d -name ".?*" -maxdepth 1 -exec mv '{}' $GRAV_ROOT/ \; # because above match expression does not include hidden dirs, .github etc
  find . -type f -maxdepth 1 -exec mv {} $GRAV_ROOT/ \;
}

GravSetupRobotsTxt() {
  # Copy robots.txt file with disallow everything directive if set
  ROBOTS_DISALLOW=${ROBOTS_DISALLOW:-"false"}
  if [[ $ROBOTS_DISALLOW == "AI_BOTS" ]]; then
    LogAction "Discouraging AI bots only with robots.txt"
    cat /tmp/extras/robots.ai-bots.txt $GRAV_ROOT/robots.txt > _robots.ai-bots.txt \
      && mv -fv _robots.ai-bots.txt $GRAV_ROOT/robots.txt \
      || LogError "Could not create custom robots.txt"
  elif [[ $ROBOTS_DISALLOW == "true" ]]; then
    LogAction "Copying discouraging robots.txt"
    cp -fv /tmp/extras/robots.disallow.txt $GRAV_ROOT/robots.txt \
      || LogError "Could not create restrictive robots.txt"
  else
    LogInfo "Using Grav's default robots.txt"
  fi
}

GravSetPermissions() {
  # Set Permissions, based on https://learn.getgrav.org/17/troubleshooting/permissions#different-accounts-fix-permissions-manually
  # NB: piping to xargs because find's -exec flag syntax makes serving fail for some reason

  cd $GRAV_ROOT
  LogAction "Setting permissions with chmod (+ chown, umask)"

  find . $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 -r chown www-user:www-user
  find . -type f $PERMISSIONS_GLOBAL $PERMISSIONS_FILES -print0 | xargs -0 -n1 chmod 664
  find ./bin -type f $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 chmod 775
  find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod 775
  find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod +s
  umask 0002
}

InitGravScheduler() {
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
}
