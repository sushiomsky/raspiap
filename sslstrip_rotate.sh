#!/bin/bash

date=`date "+%Y-%m-%dT%H:%M:%S"`

#cd /root
#./sslstrip_parser.py >> sslstrip_parser.out
killall -15 sslstrip
sleep 3
nice -n -5 sslstrip -f -w /var/log/sslstrip/dump-$date  2>&1 >> /var/log/sslstrip.log&

