#!/bin/bash
gpio  export 17 out
gpio export 22 out
gpio export 24 out

gpio -g write 17 1
gpio -g write 22 1
gpio -g write 24 1
sleep 2
gpio -g write 17 0
gpio -g write 22 0
gpio -g write 24 0
sleep 1
gpio -g write 17 1
gpio -g write 22 1
gpio -g write 24 1
sleep 2
gpio -g write 17 0
gpio -g write 22 0
gpio -g write 24 0








