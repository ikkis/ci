#!/bin/sh
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file bootstrap.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

##application config ##:x
LOCAL_TEST="$(readlink -f $(dirname $(readlink -f $0))/../)"
LOCAL_TEST_BIN="$LOCAL_TEST/bin"
LOCAL_TEST_CONF="$LOCAL_TEST/conf"
TODAY=`date +"%Y-%m-%d"`

function load_lib(){
    source $LOCAL_TEST_BIN/commonlib.sh
    source $HOME/.bash_profile 1>/dev/null 2>/dev/null
}

function check_application(){
    ini_check MODULE 1
    ini_check CI_PATH 1
    ini_check CI_OUTPUT_PATH 1
    ini_check CI_OUTPUT_VERSION 1
    ini_check LOCAL_WORKSPACE 1
    ini_check LOCAL_OUTPUT_PATH 1
    ini_check LOCAL_OUTPUT_TMP_PATH 1
    ini_check LOCAL_ARCHIVE_PATH 1
    ini_check ARCHIVE_HOST 1
    ini_check ARCHIVE_PATH 1

    #自定义覆盖bash_profile默认值
    ini_check JAVA_HOME

    ini_check CI_HOST
    ini_check BUILD_HOST
    ini_check BUILD_USER
    ini_check BUILD_PASSWD
    ini_check BUILD_SCRIPT
    ini_check BUILD_PACKAGE
    ini_check BUILD_OUTPUT_PATH
    ini_check BUILD_OUTPUT_NAME
    ini_check BUILD_OUTPUT_NAME_EXTENSION
    ini_check BUILD_RESOURCE_PATH 
    ini_check BUILD_RESOURCE_OUTPUT_PATH 
    ini_check BUILD_RESOURCE_MODULE 
    ini_check BUILD_RESOURCE_TEMPLATE_PATH 
    ini_check MONITOR_SERVER 
          
}

function check_config(){
    ini_check APP_MODE 1 
    ini_check DEPLOY_PACKAGE 1
    ini_check DEPLOY_HOST
    ini_check DEPLOY_SSHPORT

    ini_check SERVER_ROOT 
    ini_check SERVER_PATH
    ini_check SERVER_CONF

    ini_check DEPLOY_SERVER
    ini_check DEPLOY_SCRIPT
    ini_check DEPLOY_INCLUDE
    ini_check DEPLOY_EXCLUDE

    ini_check RESOURCE_SERVER_HOST
    ini_check RESOURCE_SERVER_TEAM
    ini_check RESOURCE_SERVER_DOMAIN
    ini_check RESOURCE_SERVER_URI
    ini_check RESOURCE_SERVER_NAME
    ini_check RESOURCE_SERVER_PORT
    ini_check RESOURCE_SERVER_ROOT
    ini_check RESOURCE_SERVER_PATH
    ini_check RESOURCE_SERVER_NO_CLUDE
    ini_check RESOURCE_SERVER_INCLUDE
    ini_check RESOURCE_SERVER_EXCLUDE

    ini_check DEPLOY_NOBACKUP 
    ini_check TOMCAT_NAME 
    ini_check TOMCAT_PATH 
    ini_check SERVER_NAME 
    ini_check SERVER_HOST 
    ini_check SERVER_DOMAIN 
    ini_check SERVER_DESC 
    ini_check SERVER_PORT
    ini_check SERVER_URI
    ini_check TEST_CASE
    ini_check UNIT_TEST
    ini_check ONLINE_TOKEN
}

function load_conf(){
    OUTPUT_PATH="output"
    OUTPUT_VERSION="version.ini"
    #first
    [ -f $LOCAL_TEST/$OUTPUT_VERSION ] && source $LOCAL_TEST"/$OUTPUT_VERSION"
    [ -f $LOCAL_TEST_CONF"/application.ini" ] && source $LOCAL_TEST_CONF"/application.ini" 
    [ $APP_MODE"x" == "x" ] && APP_MODE="test"
    [ -f $LOCAL_TEST_CONF/config-${APP_MODE}.ini ] && source $LOCAL_TEST_CONF"/config-${APP_MODE}.ini" 
    #again
    [ -f $LOCAL_TEST/$OUTPUT_VERSION ] && source $LOCAL_TEST"/$OUTPUT_VERSION"
}

function init_application(){
    [ "$MODULE""x" == "x" ] &&
        MODULE=`git remote -v 2>/dev/null | head -n1 | awk -F"\t" '{print $2}' | awk -F" " '{print $1}' | awk -F"/" '{print $NF}' | awk -F"." '{print $1}'`
    
    if [ "$CI_PATH""x" == "x" ]; then
         if [ "$MODULE" == "se-ci" ] ; then
             CI_PATH="."
         elif [ $WORKSPACE"x" != "x" ] ; then
             local_cmd cd $WORKSPACE 
             CI_PATH=`find -name ci | sed -e 's/\.\///' | grep -v "resource" | head -n1 `
         fi
    fi

    [ "$CI_PATH""x" == "x" ] && CI_PATH="ci"

    if [ "$CI_PATH""x" == ".x" ] ; then
        LOCAL_WORKSPACE=$LOCAL_TEST
    else
	LOCAL_WORKSPACE=`echo $LOCAL_TEST | sed -e 's|'$CI_PATH'$||'`
    fi

    [ "$BUILD_PACKAGE""x" == "x" ] && BUILD_PACKAGE=$DEPLOY_PACKAGE
    [ "$BUILD_PACKAGE""x" == "x" ] && BUILD_PACKAGE="prod"
    [ "$CI_OUTPUT_PATH""x" == "x" ] && CI_OUTPUT_PATH="$CI_PATH/$OUTPUT_PATH"
    [ "$CI_OUTPUT_TMP_PATH""x" == "x" ] && CI_OUTPUT_TMP_PATH=".output"
    [ "$CI_OUTPUT_VERSION""x" == "x" ] && CI_OUTPUT_VERSION=$CI_PATH"/$OUTPUT_VERSION"
    LOCAL_OUTPUT_PATH="$LOCAL_WORKSPACE/$CI_OUTPUT_PATH"
    LOCAL_OUTPUT_TMP_PATH="$LOCAL_WORKSPACE/$CI_OUTPUT_TMP_PATH"

    #jenkins
    ARCHIVE_HOST="ci.lianjia.com"
    ARCHIVE_USER="work"
    ARCHIVE_PASSWD="homelink"
    ARCHIVE_PATH="/home/work/jenkins_home/jobs"
      
    job_name=`echo ${JOB_NAME}| sed 's/promotion/promotions/g'`
    parent_job_name=`echo $job_name| sed 's/\/.*//g'`
      
    LOCAL_ARCHIVE_PATH="${ARCHIVE_PATH}/$parent_job_name/builds/${PROMOTED_NUMBER}/archive/$CI_OUTPUT_PATH"

    
    [ "$BUILD_USER""x" == "x" ] && BUILD_USER="work"
    [ "$BUILD_PASSWD""x" == "x" ] && BUILD_PASSWD="homelink1"

    [ "$BUILD_RESOURCE_PATH""x" == "x" ] && BUILD_RESOURCE_PATH="resource"
    [ "$BUILD_RESOURCE_OUTPUT_PATH""x" == "x" ]  && BUILD_RESOURCE_OUTPUT_PATH="$BUILD_RESOURCE_PATH/dest"  
    [ "$BUILD_RESOURCE_MODULE""x" == "x" ] && BUILD_RESOURCE_MODULE=$MODULE

    MONITOR_SERVER="http://lts.ci.lianjia.com/api/monitor"

    [ "$BUILD_HOST""x" == "x" ] && CI_HOST=$BUILD_HOST
    [ "$CI_HOST""x" == "x" ] && CI_HOST=`hostname -i`
 

}


function init_config(){
    [ "$SERVER_HOST""x" == "x" ] && SERVER_HOST=$DEPLOY_HOST
    [ "$SERVER_CONF""x" == "x" ] && SERVER_CONF=$LOCAL_TEST_CONF"/sed-${APP_MODE}.ini"

    [ "$SERVER_TEAM""x" == "x" ] &&
        SERVER_TEAM=`git remote -v 2>/dev/null | head -n1 | awk -F"\t" '{print $2}' | awk -F" " '{print $1}' | awk -F":" '{print $NF}' | awk -F"/" '{print $1}'`

    #换名字，为了兼容
    [ "$RESOURCE_SERVER_TEAM""x" == "x" ] && RESOURCE_SERVER_TEAM="lianjia-fe"
    [ "$RESOURCE_SERVER_NAME""x" == "x" ] && RESOURCE_SERVER_NAME="resource"
    [ "$RESOURCE_SERVER_HOST""x" == "x" ] && RESOURCE_SERVER_HOST=$RESOURCE_DEPLOY_HOST
    [ "$RESOURCE_SERVER_ROOT""x" == "x" ] && RESOURCE_SERVER_ROOT=$RESOURCE_DEPLOY_ROOT
    [ "$RESOURCE_SERVER_ROOT""x" == "x" ] && RESOURCE_SERVER_ROOT=$RESOURCE_SERVER_TEAM
    [ "$RESOURCE_SERVER_URI""x" == "x" ] && RESOURCE_SERVER_URI=$MODULE
    [ "$RESOURCE_SERVER_PATH""x" == "x" ] && RESOURCE_SERVER_PATH=$RESOURCE_DEPLOY_PATH
    [ "$RESOURCE_SERVER_ROOT""x" != "x" ] && [ "$RESOURCE_SERVER_PATH""x" == "x" ] && RESOURCE_SERVER_PATH="$RESOURCE_SERVER_ROOT/${MODULE}" 
    [ "$RESOURCE_SERVER_INCLUDE""x" == "x" ] && RESOURCE_SERVER_INCLUDE="$RESOURCE_DEPLOY_INCLUDE" 
    [ "$RESOURCE_SERVER_EXCLUDE""x" == "x" ] && RESOURCE_SERVER_EXCLUDE="$RESOURCE_DEPLOY_EXCLUDE" 
    CI_ROOT=`echo $CI_PATH | awk -F"/" '{print $1}'`
    RESOURCE_ROOT=`echo $BUILD_RESOURCE_OUTPUT_PATH | awk -F"/" '{print $1}'`
    [ "$RESOURCE_SERVER_INCLUDE""x" == "x" ] && RESOURCE_SERVER_INCLUDE="$RESOURCE_ROOT,$CI_ROOT" 


    [ "$SERVER_ROOT""x" == "x" ] && SERVER_ROOT=$DEPLOY_ROOT
    [ "$SERVER_ROOT""x" == "x" ] &&  SERVER_ROOT=$SERVER_TEAM

    [ "$SERVER_PATH""x" == "x" ] && SERVER_PATH=$DEPLOY_PATH
    [ "$SERVER_NAME""x" == "x" ] && SERVER_NAME=$DEPLOY_SERVER 
    [ "$SERVER_NAME""x" == "x" ] && SERVER_NAME=$MODULE
    [ "$SERVER_DESC""x" == "x" ] && SERVER_DESC=$DESC
    ##如果单次部署，修正一下输入格式(name:port)
    [ "$SERVER_PORT""x" == "x" ] &&
        SPORT=`echo $SERVER_NAME | awk -F";" '{print $1}' | awk -F":" '{print $2}'` &&
        [ "$SPORT""x" != "x" ] && SERVER_PORT=$SPORT
    
    [ "$SERVER_PATH""x" == "x" ] && SERVER_PATH="$SERVER_ROOT/${SERVER_NAME}" 

    [ "$TOMCAT_ROOT_PATH""x" == "x" ] && TOMCAT_ROOT_PATH="$HOME/local"
    [ "$TOMCAT_NAME""x" == "x" ] && TOMCAT_NAME="tomcat-"$SERVER_NAME"-"$SERVER_PORT
    [ "$TOMCAT_PATH""x" == "x" ] &&  TOMCAT_PATH=$TOMCAT_ROOT_PATH"/"$TOMCAT_NAME
    [ "$TOMCAT_LOG_FILE""x" == "x" ] && TOMCAT_LOG_FILE=$TOMCAT_PATH/logs/catalina.${TODAY}.log
    [ "$TOMCAT_STARTUP_TIMEOUT""x" == "x" ] && TOMCAT_STARTUP_TIMEOUT=100
    [ "$SERVER_URI""x" == "x" ] && SERVER_URI="/"

    JACOCO_NAME="jacocoagent.jar"
    JACOCO_AGENT="$LOCAL_TEST_BIN/$JACOCO_NAME"
    JACOCO_EXEC_NAME="jacoco-it.exec"
    JACOCO_BUILD_FILE="$LOCAL_WORKSPACE/$CI_PATH/bin/build.xml"
    JACOCO_OUTPUT_EXEC="$LOCAL_WORKSPACE/$CI_OUTPUT_PATH/${JACOCO_EXEC_NAME}"
    [ "$JACOCO_HOST""x" == "x" ] && JACOCO_HOST=$CI_HOST
    [ "$JACOCO_PORT""x" == "x" ] && 
        let "JACOCO_PORT=$SERVER_PORT + 1"

    [ "$JACOCO_INCLUDES""x" == "x"  ] && JACOCO_INCLUDES="com.lianjia.*"
    [ "$JACOCO_COVERAGE""x" != "x" ] &&
    [ "$JAVA_OPTS""x" == "x"  ] &&
    [ "$DEPLOY_SCRIPT""x" == "tomcat.shx"  ] &&
       JAVA_OPTS=$JAVA_OPTS" -javaagent:$JACOCO_AGENT=includes=$JACOCO_INCLUDES,output=tcpserver,port=$JACOCO_PORT,address=$JACOCO_HOST "

    [ "$DEPLOY_SSHPORT""x" == "x" ] && DEPLOY_SSHPORT="22"
}

function ci_init(){
    load_conf
    init_application
    init_config
    check_application
    check_config
}

main(){
   load_lib
   ci_init 
}

main 
