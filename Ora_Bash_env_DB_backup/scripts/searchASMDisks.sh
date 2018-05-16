#!/bin/sh

FILES=/dev/dm-*

LOG_FILE=/tmp/checkDMDecice.log
 
echo "Info - query all dem devices - start at  -- `date` -- " > $LOG_FILE
 
for f in $FILES
do
  echo "Info - try to read device file $f ...."    >> $LOG_FILE
  oracleasm querydisk  $f                          >> $LOG_FILE
done
 
echo "Info - finish at  -- `date` -- "        >> $LOG_FILE