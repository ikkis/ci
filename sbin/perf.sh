#!/bin/sh

user=`cat user.list`
#user="1 2 3 4 5 6"
max=50
counter=0
for ucid in $user
do
    while (( 1 == 1 ))
    do
        [ $counter -eq $max ] && counter=`ps aux | grep "python browser.py" | grep -v "grep" | wc -l` && continue
        echo $counter":"$ucid
        nohup python browser.py $ucid &
        break
    done
    let "counter++"
done

#uptime
#dmesg | tail
#vmstat 1
#mpstat -P ALL 1
#pidstat 1
#iostat -xz 1
#free -m
#sar -n DEV 1
#sar -n TCP,ETCP 1
#top
