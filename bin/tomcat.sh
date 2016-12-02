#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file tomcat.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

SUCC_MESSAGE="Server startup"
ERROR_MESSAGE=" Error "
DIV_FLAG=`date +"%b %d, %Y%l:%M:%S %p"`" $TOMCAT_NAME start" 

[ ! -d  $TOMCAT_PATH ]  && 
   Print $LOG_WARNING "tomcat not found [$TOMCAT_PATH]"

[ -f $TOMCAT_PATH/bin/setenv.sh ] && sed -i '/'$JACOCO_NAME'/d' $TOMCAT_PATH/bin/setenv.sh

[ -d  $TOMCAT_PATH/bin ]  && 
  [ "$JACOCO_COVERAGE""x" != "x" ] &&
    [ "$JAVA_OPTS""x" != "x" ] &&
        touch $TOMCAT_PATH/bin/setenv.sh &&
            echo "JAVA_OPTS=\$JAVA_OPTS\"$JAVA_OPTS\"" >> $TOMCAT_PATH/bin/setenv.sh

function port_check(){
    netstat  -lnpt |  awk -F" " '{print $4}' | grep "$SERVER_PORT"
    ret=$?
    [ $ret -eq 0  ] && echo "find [$SERVER_PORT] exist." && return 0
    return 1

}

function startup_check(){
    line=`grep -n "$DIV_FLAG" $TOMCAT_LOG_FILE  | head -n1 | awk -F":" '{print $1}'`
    [ "$line""x" == "x" ] && Print $LOG_FATAL "can't find [$DIV_FLAG] in [$TOMCAT_LOG_FILE]" && exit 255

    tail -n +$line $TOMCAT_LOG_FILE | grep "$SUCC_MESSAGE"
    ret=$?
    [ $ret -eq 0 ] && Print $LOG_NOTICE "find [$SUCC_MESSAGE] in [$TOMCAT_LOG_FILE]" &&  return 0
    return 1
}

function process_kill(){
    int=1
    while(( $int<= 10 ))
    do
        pid=`ps -ef|grep $TOMCAT_NAME| grep "org.apache.catalina.startup.Bootstrap start" | grep -v "grep"|awk '{print $2}'`
        [ "$pid""x" == "x" ] && Print $LOG_NOTICE "check process kill success." && return 0
 
        local_cmd kill -9  $pid 
  
        let "int++"
        sleep 1 
    done
    Print $LOG_FATAL "check process kill timeout." && return 1
}

function process_shutdown(){
    msg=`which supervisorctl >/dev/null && sudo supervisorctl stop $TOMCAT_NAME`
    echo $msg | grep "$TOMCAT_NAME: stopped"
    if [ $? -gt 0  ] ; then
        echo $msg | grep "$TOMCAT_NAME: ERROR (not running)"
        if [ $? -gt 0  ] ; then
            $TOMCAT_PATH/bin/shutdown.sh
        fi
    fi

    int=1
    while(( $int<= 10 ))
    do
        pid=`ps -ef|grep $TOMCAT_NAME| grep "org.apache.catalina.startup.Bootstrap start" |grep -v "grep"|awk '{print $2}'`
        [ "$pid""x" == "x" ] && Print $LOG_NOTICE "check process shutdown success." && return 0
 
        let "int++"
        sleep 1 
    done
    Print $LOG_FATAL "check process shutdown timeout." && return 1
}

function process_start(){
    echo "$DIV_FLAG" >> $TOMCAT_LOG_FILE

    #有没有supervisorctl
    msg=`which supervisorctl >/dev/null && sudo supervisorctl start $TOMCAT_NAME`
    echo $msg | grep "$TOMCAT_NAME: started"
    if [ $? -gt 0  ] ; then
        local_cmd nohup $TOMCAT_PATH/bin/startup.sh &
    fi

    int=1
    while(( $int<= $TOMCAT_STARTUP_TIMEOUT ))
    do
        startup_check
        [ $? -eq 0 ] && Print $LOG_NOTICE "check process startup success." && return 0
        let "int++"
        sleep 1 
    done
    Print $LOG_FATAL "check process startup timeout." && return 1
}

function server_monitor(){
    line=`grep -n "$DIV_FLAG" $TOMCAT_LOG_FILE  | head -n1 | awk -F":" '{print $1}'`
    [ "$line""x" == "x" ] && Print $LOG_FATAL "can't find [$DIV_FLAG] in [$TOMCAT_LOG_FILE]" && exit 255

    tail -n +$line $TOMCAT_LOG_FILE | grep -i "$ERROR_MESSAGE" | grep -v " INFO " | grep -v " DEBUG " | grep -v " error "
    ret=$?
    [ $ret -eq 0 ] && Print $LOG_FATAL "find [$ERROR_MESSAGE] in [$TOMCAT_LOG_FILE]" && return 1
    Print $LOG_NOTICE "not find [$ERROR_MESSAGE] in [$TOMCAT_LOG_FILE]" 
    return 0
}

function process_stop(){
    process_shutdown
    ret=$?
    [ $ret -eq 0 ]  &&  return 0

    process_kill 
    ret=$?
    return $ret
}

function server_stop(){
    Print $LOG_NOTICE "server stop..."
    
    process_stop
    ret=$?
    [ $ret -gt 0  ] &&  Print $LOG_FATAL "process stop fail."  && exit 255
    Print $LOG_NOTICE "process stop success."
    
    port_check
    ret=$?
    [ $ret -eq 0  ] && Print $LOG_FATAL "port check fail."  && exit 255
    Print $LOG_NOTICE "port check success."
   
    Print $LOG_NOTICE  "server stop...[ok]."
}

function init_conf(){
    [ "$SERVER_CONF""x" == "x" ] && return
    [ ! -f $SERVER_CONF  ] && return
    cd $LOCAL_WORKSPACE
    while read line
    do
        ini_replace $line 
    done < $SERVER_CONF
    cd - >/dev/null
}

function server_start(){
    Print $LOG_NOTICE "server start..."
    init_conf
    process_start
    ret=$?
    [ $ret -gt 0  ] && Print $LOG_FATAL "process start fail."  && exit 255
    Print $LOG_NOTICE "process start success."
    
    port_check
    ret=$?
    [ $ret -gt 0  ] && Print $LOG_FATAL "port check fail."  && exit 255
    Print $LOG_NOTICE "port check success."

    server_monitor 
    ret=$?
    [ $ret -gt 0  ] && Print $LOG_FATAL "server monitor fail."  && exit 255
    Print $LOG_NOTICE "server monitor success."

    Print $LOG_NOTICE "server start...[ok]"
}

case $1 in 
    "start") echo "$0 start"
            server_stop
            server_start
    ;;

    "stop") echo "$0 stop"
    ;;
esac
exit 0
