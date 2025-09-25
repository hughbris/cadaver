#!/bin/sh

#
# Grav files setup

GravSetupPersistent() {

  if [[ $(ls $GRAV_ROOT/backup/* 2>/dev/null | wc -l) -gt 0 || -e $GRAV_ROOT/backup/.gitkeep ]]; then
    LogInfo "Using existing backup directory"
  else
    LogAction "Fresh install, moving backup"
    cp -faR $GRAV_TEMP/backup $GRAV_ROOT/ \
      && LogSuccess "Moved backup" \
      || LogError "Could not move backup"
  fi

  if  [[ $(ls $GRAV_ROOT/logs/* 2>/dev/null | wc -l) -gt 0 || -e "$GRAV_ROOT/logs/.gitkeep" ]]; then
    LogInfo "Using existing logs directory"
  else
    LogAction "Fresh install, moving logs"
    cp -faR $GRAV_TEMP/logs $GRAV_ROOT/ \
      && LogSuccess "Moved logs" \
      || LogError "Could not move logs"
  fi

  if [[ -e $GRAV_ROOT/user/config/site.yaml ]]; then
    LogInfo "Using existing user directory"
  else
    LogAction "Fresh install, moving user directories"
    mkdir -p $GRAV_ROOT/user
    cp -faR $GRAV_TEMP/user/* $GRAV_ROOT/user/ \
      && LogSuccess "Moved user directories" \
      || LogError "Could not move all user directories"
  fi
}

GravSetupEphemeral() {
  cd $GRAV_TEMP
  LogAction "Moving Grav core"

  # directories ..
  find ./* -type d \( ! -regex '^\./\(user\|backup\|logs\)$' \) -maxdepth 0 \
    -exec mv '{}' $GRAV_ROOT/ \;
  # Now because above match expression does not include hidden dirs, .github etc ..
  find . -type d -name ".?*" -maxdepth 1 \
    -exec mv '{}' $GRAV_ROOT/ \;

  # files ..
  find . -type f -maxdepth 1 \
    -exec mv '{}' $GRAV_ROOT/ \;
}

GravSetupRobotsTxt() {
  # Install a different robots.txt file if set

  cd $GRAV_TEMP
  ROBOTS_DISALLOW=${ROBOTS_DISALLOW:-"false"}
  if [[ $ROBOTS_DISALLOW == "AI_BOTS" ]]; then
    LogAction "Discouraging AI bots only with robots.txt"
    cat /tmp/extras/robots.ai-bots.txt $GRAV_ROOT/robots.txt > _robots.ai-bots.txt \
      && cp -fav _robots.ai-bots.txt $GRAV_ROOT/robots.txt \
      || LogError "Could not create custom robots.txt"
  elif [[ $ROBOTS_DISALLOW == "true" ]]; then
    LogAction "Copying discouraging robots.txt"
    cp -fav /tmp/extras/robots.disallow.txt $GRAV_ROOT/robots.txt \
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

  find . $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 -r chown www-data:www-data
  find . -type f $PERMISSIONS_GLOBAL $PERMISSIONS_FILES -print0 | xargs -0 -n1 chmod 664
  find ./bin ./vendor/bin -type f $PERMISSIONS_GLOBAL -print0 | xargs -0 -n1 chmod 775
  find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod 775
  find . -type d $PERMISSIONS_GLOBAL $PERMISSIONS_DIRS -print0 | xargs -0 -n1 chmod +s
  umask 0002
  LogSuccess "Done setting permissions"
}
