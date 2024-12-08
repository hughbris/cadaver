#!/bin/sh

#
# Logging
# Thanks to @dsavell: https://github.com/dsavell/docker-grav/blob/da929c8d7af2696bce6b7f1cc9124e67f58430be/files/home/grav/server/helpers.sh
#

export LINE='\n'
export RESET='\033[0m'              # Text Reset
export WhiteText='\033[0;37m'       # White (normal)
export WhiteBoldText='\033[1;37m'   # White
export BlueBoldText='\033[1;34m'    # Blue
export RedBoldText='\033[1;31m'     # Red
export GreenBoldText='\033[1;32m'   # Green
export YellowBoldText='\033[1;33m'  # Yellow
export CyanBoldText='\033[1;36m'    # Cyan
export MagentaBoldText='\033[1;35m' # Magenta

export EmojiInfo="\xf0\x9f\x9b\x88"
export EmojiHazard="\xe2\x9b\x9b"
export EmojiCross="\xf0\x9f\x97\xb6"
export EmojiTick="\xf0\x9f\x97\xb8"
export EmojiFlash="\xf0\x9f\x97\xb2"
export EmojiDebug="\xf0\x9f\x90\x9b"

Log() {
  local message="$1"
  local threshold="${2:-0}"
  local color="$3"
  local symbol="$4"
  local prefix="$5"
  local suffix="$6"
  if [ $symbol ]; then
    local symbols="$symbol $symbol $symbol"
    local symbols_start="$symbols "
    local symbols_end=" $symbols"
  fi

  if [[ $LOG_LEVEL -ge $threshold ]]; then
    echo -e "$color$symbols_start$prefix$message$suffix$symbols_end$RESET"
  fi
}

LogSplash() {
  printf '%b
                          _|                                            
  _|_|_|    _|_|_|    _|_|_|    _|_|_|  _|      _|    _|_|    _|  _|_|  
_|        _|    _|  _|    _|  _|    _|  _|      _|  _|_|_|_|  _|_|      
_|        _|    _|  _|    _|  _|    _|    _|  _|    _|        _|        
  _|_|_|    _|_|_|    _|_|_|    _|_|_|      _|        _|_|_|  _|        

                     Caddy serving Grav in Docker
' $CyanBoldText
  echo -e "$RESET"
}

LogInfo() {
  Log "$1" 8 "$BlueBoldText" $EmojiInfo
}
LogWarn() {
  Log "$1" 3 "$YellowBoldText" $EmojiHazard
}
LogError() {
  Log "$1" 1 "$RedBoldText" $EmojiCross
}
LogSuccess() {
  Log "$1" 6 "$GreenBoldText" $EmojiTick
}
LogAction() {
  Log "$1" 5 "$MagentaBoldText" $EmojiFlash
}
LogDebug() {
  Log "$1" 10 "$WhiteBoldText" $EmojiDebug
}
