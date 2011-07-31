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

  io_error_code=`echo "SHOW SLAVE STATUS\G" | mysql -u slave_check -p$SLAVE_PASSWORD | grep Last_IO_Errno | sed 's/[^0-9]//g'`
  sql_error_code=`echo "SHOW SLAVE STATUS\G" | mysql -u slave_check -p$SLAVE_PASSWORD | grep Last_SQL_Errno | sed 's/[^0-9]//g'`

  if [ $io_error_code == "0" -a $sql_error_code == "0" ]; then
    # Remove all lines from status file except for one
    echo "OK" > $STATUS_FILE
  
    # Remove the suppression file
    if [ -e $suppression_file ]; then
      rm $suppression_file
    fi
  else
    # Log the errors and update the status file
    echo "SHOW SLAVE STATUS\G" | mysql -u slave_check -p$SLAVE_PASSWORD | grep Err | awk '{print d,$1,$2;}' "d=$(date)" >> $STATUS_FILE
    echo "SHOW SLAVE STATUS\G" | mysql -u slave_check -p$SLAVE_PASSWORD | grep Err | awk '{print d,$1,$2;}' "d=$(date)" >> $log_file
  fi

  # Only send an email if we have had 3 error codes, i.e. 18 lines
  if [ `cat $STATUS_FILE | wc -l` -gt 18 ]; then
    # Only send one email
    if [ ! -e $suppression_file ]; then
      cat $STATUS_FILE | mail --subject="MySQL Master-Slave Error" $ERROR_EMAIL_RECIPIENTS
      touch $suppression_file
    fi 
  fi

  sleep 5s
done
