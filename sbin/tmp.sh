#!/bin/sh

dnIp='lianjia.com'
if ! [[ $dnIp =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]
|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]
    then
       echo ""
       #echo ${BASH_REMATCH[1]}
       #echo ${BASH_REMATCH[2]}
       #echo ${BASH_REMATCH[3]}
       #echo ${BASH_REMATCH[4]}
   else
       echo "Resolving:$dnIp"
       dnIp=`nslookup $dnIp | grep "Address: " | sed -e 's/Address: //'`
       echo "$dnIp"
   fi
