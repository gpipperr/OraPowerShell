#!/bin/sh
#
#
#  read the interface statistic and write the information to a log file
#
#
#
#  # M H  D M
#  #backup and delete archivelog every two hours
#  */1 * * * * /home/oracle/scripts/checkDroppedPackage.sh	
#
########## Environment ##############
DAY_OF_WEEK="`date +%w`"
export DAY_OF_WEEK 

DAY="`date +%d`"
export DAY

# Home of the scrips
SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS=`dirname "$SCRIPTPATH{}"`
export SCRIPTS

########## Configuration ##############
INTERFACE="eth1"
HOST=`hostname -a`


######### Log file Handling ###########
OVERWRITE="false"

# check if a new file must be created
if [ ! -e $SCRIPTS/${HOST}_${INTERFACE}_${DAY}.log ]; then
  OVERWRITE="true"
else
  # check the age of the file
  # if older then one day overwrite
  FILEAGE_SECONDS=`date -d "now - $( stat -c "%Y" $SCRIPTS/${HOST}_${INTERFACE}_${DAY}.log ) seconds" +%s`
  
  if [ -z "$FILEAGE_SECONDS"  ]; then 
    FILEAGE_SECONDS=0;
  fi
  
  if [ "$FILEAGE_SECONDS" -gt 86400 ]; then
		OVERWRITE="true"
  fi
  
fi

if [ "$OVERWRITE" = "true" ]; then
	echo "----------------------- start new Day ${DAY} -------------------------------"          >  $SCRIPTS/${HOST}_${INTERFACE}_${DAY}.log 2>&1
	echo "Iface       MTU Met    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg"   >> $SCRIPTS/${HOST}_${INTERFACE}_${DAY}.log 2>&1
fi



# get the figures
/bin/netstat -i | /bin/grep "${INTERFACE} "  | /bin/awk '{print strftime("%Y-%m-%d %r") ":" $0; }' >> $SCRIPTS/${HOST}_${INTERFACE}_${DAY}.log

#
 