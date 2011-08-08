#!/bin/bash

#
# This script monitors the number or seconds the slave is behind the master and
# writes it to the main log
#
# @author Tom Haskins-Vaughan <tomh@janeiredale.com>
# @since  2011-07-11

# Load config files
source $HOME/mysql-slave-monitor/config.defaults
source $HOME/mysql-slave-monitor/config.local

SECONDS=`echo "SHOW SLAVE STATUS\G" | mysql -u $SLAVE_USER -p$SLAVE_PASSWORD -h $SLAVE_HOST | grep Seconds_Behind_Master | awk '{ print $2 }'`

echo "`date` $SECONDS_BEHIND_LABEL: $SECONDS" >> $LOG_FILE
