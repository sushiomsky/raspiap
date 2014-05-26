#!/bin/bash

date=`date "+%Y-%m-%dT%H:%M:%S"`

cd /usr/local/src/raspiap/sslstrip_parser
nice -n 10 ./sslstrip_parser.py >> /var/log/sslstrip_parser.out

killall -15 sslstrip
sleep 3
nice -n -10 sslstrip -f -w /var/log/sslstrip/dump-$date  >> /var/log/sslstrip_daemon.log &
rm sslstrip.log
ln -s /var/log/sslstrip/dump-$date sslstrip.log

