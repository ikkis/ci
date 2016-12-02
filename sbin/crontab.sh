#!/bin/sh

source ~/.bash_profile
date=`date -d "-1 day" +"%Y%m%d"`
ROOT=$HOME
WORKSPACE=$ROOT/local

minDay=0
minHistory=1
maxHistory=20

function run_rm(){
   file=$1
   count=$2
   [ "$file""x" == "x" ] && return
   [ "$count""x" == "x" ] && return

   [ $count -le $minHistory ] && return
   dir=`pwd`
   echo "rm -rf $dir/$file"
   rm -rf $file
}

function filter_rm(){
    #files=$1
    #[ "$files""x" == "x" ] && return
    #echo $files | awk -F"/" '{print $NF}'  | awk -F"." '{print $0"\t"$1}' > rm.tmp

    rm -f rm*.tmp
    ls | awk -F"/" '{print $NF}' | awk -F"." '{print $0"\t"$1}' | sort -k1 > rm_all.tmp 
    ls | awk -F"/" '{print $NF}' | awk -F"." '{print $0"\t"$1}' | cut -f2 | sort | uniq -c | awk -F" " '{print $2"\t"$1}' > rm_count.tmp
    awk -F"\t" 'NR==FNR{a[$1] = $2}NR>FNR{print $0"\t"a[$2]; a[$2] = a[$2] - 1;}' rm_count.tmp rm_all.tmp > rm_all_count.tmp

    awk -F"\t" 'NR==FNR{if($3 > '$maxHistory') print $1"\t"$3}' rm_all_count.tmp > rm.tmp 
    find . -mindepth 1 -maxdepth 1 -mtime +$minDay | awk -F"/" '{print $NF}'  | awk -F"." '{print $0"\t"$1}' | sort -k1 > rm_timeout.tmp
    awk -F"\t" 'NR==FNR{if($2 =="") next; a[$1]=$3} NR>FNR {if(a[$1] > '$maxHistory' ||  a[$1] == '$minHistory') next; print $1"\t"a[$1];}' rm_all_count.tmp  rm_timeout.tmp >> rm.tmp 
    while read line
    do
        run_rm $line 
    done < rm.tmp
}

function exec_rm(){
   target=$@
   [ "$target""x" == "x" ] && return
   for path in $target
   do
       [ -d $path ] || continue
       cd $path
       #files=`find . -mindepth 1 -maxdepth 1 -atime +$minDay`
       #filter_rm $files
       #files=`find . -mindepth 1 -maxdepth 1 -mtime +$minDay`
       #filter_rm $files
       filter_rm
       cd - >/dev/null
   done
}

function exec_clear(){
   target=$@
   [ "$target""x" == "x" ] && return
   for log in $target
   do
       [ -f $log ] || continue
       > $log
   done
}

function clean(){
   cd ${ROOT}
   M2BAK=".m2_bak"
   mkdir -p $M2BAK 
   mv -f .m2 $M2BAK/.m2_$date

   exec_rm $M2BAK
   for release in `find -mindepth 1 -maxdepth 3 -name .release`
   do
       exec_rm $release 
   done
   exec_rm `find -name logs`
   exec_clear `find -name "*.log"`
   exec_clear `find -name "*_log.2015*"`
   exec_clear `find -name "*_log.2016*"`
   exec_clear `find -name "catalina.out"`
}

function port_check(){
    SERVER_PORT=$1
    [ "$SERVER_PORT""x" == "x" ] && return
    int=1
    while(( $int<= 20 ))
    do
        netstat  -anp | grep "$SERVER_PORT" | grep "LISTEN"
        [ $? -eq 0 ] && echo "check process success." && return 0
        let "int++"
        sleep 5 
    done
    echo "check process timeout." && return 1
}

function restart_tomcat(){
   echo "restart_tomcat"
   cd ${WORKSPACE}
   for TOMCAT_NAME in `find -mindepth 1 -maxdepth 1 -name "tomcat-*" 2>/dev/null | awk -F"/" '{print $NF}'`
   do 
       [ $TOMCAT_NAME"x" == "x" ] && continue 
       echo "${TOMCAT_NAME} start..."
       cd ${TOMCAT_NAME}
       rm -rf logs
       mkdir logs 
       TOMCAT_PORT=`echo $TOMCAT_NAME | awk -F"-" '{print $NF}'`  
       TOMCAT_PID=`ps -ef | grep $TOMCAT_NAME | grep -v "grep" | awk '{print $2}'`
       [ "${TOMCAT_PID}x" == "x" ]  || kill -9  ${TOMCAT_PID}
       if [ -f ./bin/startup.sh ] ; then
          nohup ./bin/startup.sh &
       else
          nohup ./bin/start.sh &
       fi
       cd - >/dev/null 

       port_check $TOMCAT_PORT
       [ $? -gt 0 ] && fail="$fail ${TOMCAT_NAME}" && continue
       finish="$finish ${TOMCAT_NAME}"
    done
    [ ! "$fail""x"  == "x"  ] && echo "tomcat start fail: [$fail]"
    echo "tomcat start sucess: [$finish]" 
}

function restart_mysql(){
   echo "restart_mysql"
   cd ${WORKSPACE}/mysql
   ./mysql.server stop   
   ./mysql.server start 
   port_check 6606 
}

function restart_nginx(){
   echo "restart_nginx"
   cd ${ROOT}/opbin
   sh ./nginx.sh stop
   sh ./php-fpm.sh stop
   sh ./php-fpm.sh start
   sh ./nginx.sh start
   port_check 3000 
}
function restart_redis(){
   echo "restart_redis"
   cd ${ROOT}/opbin
   sh ./redis.sh stop
   sh ./redis.sh start
   sh ./redis1.sh stop
   sh ./redis1.sh start
   port_check 6379 
   port_check 6378 
}

function restart_memcache(){
   echo "restart_memcache"
   cd ${WORKSPACE}/memcached-1.4.21
   sh ./memcached.sh stop
   sh ./memcached.sh start
   port_check 11211 
}


function restart_zookeeper(){
   echo "restart_zookeeper"
   cd ${WORKSPACE}/zookeeper-3.4.6
   sh ./bin/zkServer.sh stop
   rm -rf ~/var/zookeeper/data/*
   rm -rf ~/var/zookeeper/logs/*
   mkdir -p ~/var/zookeeper/data
   mkdir -p ~/var/zookeeper/logs
   sh ./bin/zkServer.sh start
   port_check 2800
}

function restart_activemq(){
   echo "restart_activemq"
   cd ${WORKSPACE}/apache-activemq-5.11.1
   ./bin/activemq stop
   rm -rf data/*
   ./bin/activemq start

   port_check 61616
}

function main(){
   clean
   restart_zookeeper
   restart_activemq
   restart_redis
   restart_memcache
   restart_mysql
   restart_nginx
   restart_tomcat 
}
clean
#main $@
