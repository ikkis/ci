#!/bin/sh

module=$1
sport=$2
dport=$3

[  $module"x" == "x" ] && echo "Error: bad module [$module]" && exit 1
[  $sport"x" == "x" ] && echo "Error: bad port [$sport]" && exit 2
[  $dport"x" == "x" ] && echo "Error: bad port [$dport]" && exit 3

stomcat="tomcat-"$module"-"$sport
dtomcat="tomcat-"$module"-"$dport

if [ -d $dtomcat ]; then
    echo "Warning: new tomcat has exist [$dtomcat]" 
elif [ $sport"x" == $dport"x"  ];then
    echo "Warning: port same [$sport: $dport]" 
elif [ ! -d $stomcat ]; then
   echo "src tomcat not exist, copy new"
   cp -r tomcat $dtomcat
else
   mv $stomcat $dtomcat
fi

SHUTDOWN_PORT=$(($dport + 5))
HTTP_PORT=$dport



SHUTDOWN_PORT=$(($dport + 5))
HTTP_PORT=$dport
AJP_PORT=$(($dport + 9))

sed -i  's/Server port="[0-9]*" shutdown/Server port="'$SHUTDOWN_PORT'" shutdown/' $dtomcat/conf/server.xml
[  $? != 0 ] && echo "run cmd fail: SHUTDOWN" && exit 1
sed -i  's/Connector port="[0-9]*" URIEncoding/Connector port="'$dport'" URIEncoding/' $dtomcat/conf/server.xml
[  $? != 0 ] && echo "run cmd fail: Connector HTTP" && exit 1
sed -i  's/Connector port="[0-9]*" protocol/Connector port="'$AJP_PORT'" protocol/'  $dtomcat/conf/server.xml
[  $? != 0 ] && echo "run cmd fail: AJP" && exit 1
