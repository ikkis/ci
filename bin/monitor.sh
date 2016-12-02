#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 lianjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @author shixiaoqiang@lianjia.com
# * @date 2016/05/10/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

deploy_monitor(){
    status=$1
    msg=$2
    [ "$DEPLOY_STATUS""x" == "x" ] && DEPLOY_STATUS=$status
    [ "$DEPLOY_MSG""x" == "x" ] && DEPLOY_MSG=$msg
    HOST=`hostname -i`
    NAME=`hostname -s`
    SIZE=`du -sh $LOCAL_WORKSPACE | cut -f1`
    [ "$SERVER_HOST""x" == "x" ] && SERVER_HOST=$HOST
    [ "$SERVER_HOST""x" == "127.0.0.1x" ] && SERVER_HOST=$HOST
    data="app_mode=$APP_MODE&module=$MODULE&ci_path=$CI_PATH&build=$BUILD&build_num=$BUILD_NUM&project=$PROJECT&branch=$BRANCH&commit=$COMMIT&commiter=${COMMITER}&package=$PACKAGE&server_name=$SERVER_NAME&server_port=$SERVER_PORT&server_host=$SERVER_HOST&host_name=$NAME&server_desc=$SERVER_DESC&server_domain=$SERVER_DOMAIN&server_path=$SERVER_PATH&deploy_time=$DEPLOY_TIME&deploy_status=$DEPLOY_STATUS&deploy_msg=$DEPLOY_MSG&deploy_size=$SIZE&server_team=$SERVER_TEAM&email=$EMAIL&parent=$PARENT&commit_time=$COMMIT_TIME"
    echo $data
    monitor_post $data

    #RESOURCE
    [ ! -d $LOCAL_WORKSPACE/$BUILD_RESOURCE_OUTPUT_PATH ] && return
    tag=`echo $BUILD_RESOURCE_PATH | sed -e 's/\.\///' | sed -e 's/\/*$/\//' | sed -e 's/\//_/'`
    project=${tag}"PROJECT" && [ "${!project}""x" == "x" ] && return
    clone=${tag}"CLONE"
    branch=${tag}"BRANCH"
    commit=${tag}"COMMIT"
    commiter=${tag}"COMMITER"
    email=${tag}"EMAIL"
    comment=${tag}"COMMENT"
    parent=${tag}"PARENT"
    commit_time=${tag}"COMMIT_TIME"
    size=`du -sh $LOCAL_WORKSPACE/$BUILD_RESOURCE_OUTPUT_PATH | cut -f1`
    data="app_mode=$APP_MODE&module=$MODULE&ci_path=$CI_PATH&build=$BUILD&build_num=$BUILD_NUM&project=${!project}&branch=${!branch}&commit=${!commit}&commiter=${!commiter}&package=$PACKAGE&server_name=$RESOURCE_SERVER_NAME&server_port=$RESOURCE_SERVER_PORT&server_host=$SERVER_HOST&host_name=$NAME&server_desc=$SERVER_DESC&server_domain=$RESOURCE_SERVER_DOMAIN/$RESOURCE_SERVER_URI&server_path=$SERVER_PATH/$BUILD_RESOURCE_OUTPUT_PATH&deploy_time=$DEPLOY_TIME&deploy_status=$DEPLOY_STATUS&deploy_msg=$DEPLOY_MSG&deploy_size=$size&server_team=$RESOURCE_SERVER_TEAM&email=${!email}&parent=${!parent}&commit_time=${!commit_time}"
    echo $data
    monitor_post $data
}

Main() 
{
   deploy_monitor $@ 
}

Main $@
