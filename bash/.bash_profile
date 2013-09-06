# .bash_profile

#Oracle Settings
. .profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
# Info for the Oracle settings
echo -e "\033[33m USE setdb to set Oracle Profile!\033[0m"

# see:: http://www.pipperr.de/dokuwiki/doku.php?id=windows:putty_ip_im_header

HOST_NAME_IP_ADR=`hostname -i`

function myprompt {
 
  local BLUE="\[\e[0;34m\]"
  local GREEN="\[\e[1;32m\]"
  local RED="\[\e[0;31m\]"
  local NO_COLOR="\[\e[0m\]"
  local LIGHT_BLUE="\[\e[0;36m\]"
 
  case $TERM in
    xterm*|rxvt*)
      TITLEBAR='\[\033]0;\u@\h (${HOST_NAME_IP_ADR}) (ORASID::${ORACLE_SID})  > \007\]'
      ;;
    *)
      TITLEBAR=""
      ;;
  esac
 
  PS1="$LIGHT_BLUE[${TITLEBAR}$GREEN\u@\h$RED:$LIGHT_BLUE\W ]$ $NO_COLOR"
 
  PS2='continue-> '
  PS4='$0.$LINENO+ '
 
}

function settitle {
 # fix implemet this, will be called from login.sql
 mypromt $1 $2
}

myprompt