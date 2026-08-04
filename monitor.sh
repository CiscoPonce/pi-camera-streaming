#!/bin/bash
echo "Timestamp, CPU %, Mem %, Temp"
while true; do
    TIMESTAMP=$(date +%H:%M:%S)
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    MEM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
    echo "$TIMESTAMP, $CPU, $MEM, $TEMP"
    sleep 2
done
