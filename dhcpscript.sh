#!/bin/bash
#action when a new lease is added or removed
echo  "Mac:" $2 "IP:" $3 $4 >> /var/log/leaselog.log
/root/gpio_led.sh
exit 0
