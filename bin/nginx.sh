#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file 
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

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

function server_stop(){
    echo "nginx stop"
    sh ~/opbin/php-fpm.sh stop 
    sh ~/opbin/nginx.sh stop 
    sleep 2 
}

function server_start(){
    echo "nginx start"
    init_conf
    local_cmd sh ~/opbin/php-fpm.sh start 
    local_cmd sh ~/opbin/nginx.sh start 
    sleep 2 
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
