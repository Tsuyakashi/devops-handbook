#!/bin/bash

# default nginx log file
SRC_LOG="/var/log/nginx/access.log"
# log for all with re empty
LOG1="/tmp/nginx_logger_daemon/file1.log"
# log for empty log
LOG2="/tmp/nginx_logger_daemon/file2.log"
# log for 5xx
LOG3="/tmp/nginx_logger_daemon/file3.log"
# log for 4xx
LOG4="/tmp/nginx_logger_daemon/file4.log"

STOP_FILE="/tmp/nginx_logger_daemon/stop_nginx_logger_daemon"

mkdir -p /tmp/nginx_logger_daemon

touch $LOG1 $LOG2 $LOG3 $LOG4 
    
while [ ! -f $STOP_FILE ] ; do

    tail -n 50 "$SRC_LOG" | while read line; do
        echo "$line" >> $LOG1

        code=$(echo "$line" | awk '{print $9}')

        if echo "$code" | sed -E '/5[0-9]{2}/!d' > /dev/null; then
            echo "$line" >> $LOG3
        fi

        if echo "$code" | sed -E '/4[0-9]{2}/!d' > /dev/null; then
            echo "$line" >> $LOG4
        fi

    done

    sz=$(stat -c%s $LOG1)

    if [ $sz -gt 300000 ]; then
        count=$(wc -l $LOG1 | awk '{print $1}')
        echo "$(date '+%Y-%m-%d %H:%M:%S') Main log cleaned, removed $count lines" >> $LOG2
        echo "" > $LOG1
    fi


    sleep 5

done