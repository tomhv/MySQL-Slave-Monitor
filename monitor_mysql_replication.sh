#!/bin/bash

#
# This script monitors the MySql replication and notifies the admins if it fails
#
# @author Tom Haskins-Vaughan <tom@templestreetmedia.com>
# @since  2011-06-24

# Load config files
source config.defaults
source config.local

for i in {1..9}
do

  IO_ERROR_CODE=`echo "SHOW SLAVE STATUS\G"  | mysql -u $SLAVE_USER -p$SLAVE_PASSWORD -h $SLAVE_HOST | grep Last_IO_Errno  | sed 's/[^0-9]//g'`
  SQL_ERROR_CODE=`echo "SHOW SLAVE STATUS\G" | mysql -u $SLAVE_USER -p$SLAVE_PASSWORD -h $SLAVE_HOST | grep Last_SQL_Errno | sed 's/[^0-9]//g'`

  if [ $IO_ERROR_CODE == "0" -a $SQL_ERROR_CODE == "0" ]; then
    # Remove all lines from status file except for one
    echo $STATUS_OK > $STATUS_FILE

    # Remove the suppression file
    if [ -e $EMAIL_SUPPRESSION_FILE ]; then
      rm $EMAIL_SUPPRESSION_FILE
    fi
  else
    # Log the errors and update the status file
    echo "SHOW SLAVE STATUS\G" | mysql -u $SLAVE_USER -p$SLAVE_PASSWORD -h $SLAVE_HOST | grep Err | awk '{print d,$1,$2;}' "d=$(date)" >> $STATUS_FILE
    echo "SHOW SLAVE STATUS\G" | mysql -u $SLAVE_USER -p$SLAVE_PASSWORD -h $SLAVE_HOST | grep Err | awk '{print d,$1,$2;}' "d=$(date)" >> $LOG_FILE
  fi

  # Only send an email if we have had 3 error codes, i.e. 18 lines
  if [ `cat $STATUS_FILE | wc -l` -gt 18 ]; then
    # Only send one email
    if [ ! -e $EMAIL_SUPPRESSION_FILE ]; then
      cat $STATUS_FILE | mail --subject="MySQL Master-Slave Error" $ERROR_EMAIL_RECIPIENTS
      touch $EMAIL_SUPPRESSION_FILE
    fi 
  fi

  sleep 5s
done
