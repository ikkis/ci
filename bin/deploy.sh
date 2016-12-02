#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 lianjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

check_host()
{
    remote_cmd $HOST $USER $PASSWD "pwd"
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "CHECK HOST error"
        exit 255
    fi
}

init_host()
{
    remote_cmd $HOST $USER $PASSWD "mkdir -p ~/cidir/$MODULE"
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "init host error"
        exit 255
    fi

}

wget_file()
{
    wget_file=$1
    remote_cmd $HOST $USER $PASSWD "cd ~/cidir/$MODULE && rm -rf * && wget $wget_file 2>/dev/null" 
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "wget file error"
        exit 255
    fi
}

unzip_package()
{
    baseName=`basename $wget_file`

    remote_cmd $HOST $USER $PASSWD "cd ~/cidir/$MODULE && tar -zvxf $baseName 1>/dev/null"
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "unzip package error"
        exit 255
    fi

}

deploy_online_module()
{
    DEPLOY_ROOT=`dirname $DEPLOY_PATH`
    DEPLOY_NAME=`echo $DEPLOY_PATH | awk -F"/" '{print $NF}'`
    DEPLOY_TIME=`date +"%Y%m%d%H%M%S"`
    #prefix=`echo $DEPLOY_TIME | sed -e "s/-//g" | sed -e "s/://g" | sed -e 's/ /-/g'`
    prefix=$DEPLOY_TIME
    Print $LOG_NOTICE "deploy online module start"
 
    #For params be set not in conf, such as jenkins;
    remote_cmd $HOST $USER $PASSWD "echo 'APP_MODE=\"$APP_MODE\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'JACOCO_COVERAGE=\"$JACOCO_COVERAGE\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"

    remote_cmd $HOST $USER $PASSWD "echo 'SERVER_HOST=\"$HOST\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'SERVER_PORT=\"$DEPLOY_PORT\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'SERVER_ROOT=\"$DEPLOY_ROOT\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'SERVER_PATH=\"$DEPLOY_PATH\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'DEPLOY_TIME=\"$DEPLOY_TIME\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"

    if [ "$DEPLOY_SCRIPT" != "" ]
    then
        remote_cmd $HOST $USER $PASSWD "cd ~/cidir/$MODULE/$MODULE/$CI_PATH && sh bin/$DEPLOY_SCRIPT stop"
    fi
    if [ "$DEPLOY_NOBACKUP""x" == "x"  ] ; then
        remote_cmd $HOST $USER $PASSWD "mkdir -p  $DEPLOY_ROOT/.release ; mv ~/cidir/$MODULE/$MODULE $DEPLOY_ROOT/.release/$MODULE.$prefix ; cd $DEPLOY_ROOT; rm -rf $DEPLOY_NAME; ln -sf  .release/$MODULE.$prefix $DEPLOY_NAME; ln -sf $DEPLOY_NAME/$CI_OUTPUT_VERSION $DEPLOY_NAME.version"
    else
        remote_cmd $HOST $USER $PASSWD "mkdir -p $DEPLOY_ROOT; cd $DEPLOY_ROOT; rm -rf $DEPLOY_NAME; mv ~/cidir/$MODULE/$MODULE $DEPLOY_NAME; ln -sf $DEPLOY_NAME/$CI_OUTPUT_VERSION $DEPLOY_NAME.version"
    fi

    if [ $? -ne 0 ]
    then
        remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH/$CI_PATH ;sh bin/monitor.sh 4 'path-error'"
        Print $LOG_FATAL "deploy path error"
        exit 255
    fi

    if [ "$DEPLOY_SCRIPT" != "" ]
    then
        remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH/$CI_PATH && sh bin/$DEPLOY_SCRIPT start"
        if [ $? -ne 0 ]
        then
            remote_cmd $HOST $USER $PASSWD "echo 'DEPLOY_STATUS=4' >> $DEPLOY_PATH/$CI_OUTPUT_VERSION"
            remote_cmd $HOST $USER $PASSWD "echo 'DEPLOY_MSG=\"${DEPLOY_SCRIPT} start fail\"' >> $DEPLOY_PATH/$CI_OUTPUT_VERSION"
            remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH/$CI_PATH; sh bin/monitor.sh "
            Print $LOG_FATAL "deploy start error"
            exit 255
        fi
    fi

    remote_cmd $HOST $USER $PASSWD "echo 'DEPLOY_STATUS=2' >> $DEPLOY_PATH/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "echo 'DEPLOY_MSG=\"${DEPLOY_SCRIPT}success\"' >> $DEPLOY_PATH/$CI_OUTPUT_VERSION"
    remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH/$CI_PATH; sh bin/monitor.sh"
    if [ "$DEPLOY_INCLUDE""x" != "x" ]; then
       DEPLOY_INCLUDE=`echo $DEPLOY_INCLUDE | sed -e 's/ /|/g'`
       CLEAN_CMD='rm -rf `ls | egrep -v "('$DEPLOY_INCLUDE')"`' 
       remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH && $CLEAN_CMD"
    fi
    if [ "$DEPLOY_EXCLUDE""x" != "x" ]; then
       CLEAN_CMD="rm -rf $DEPLOY_EXCLUDE" 
       remote_cmd $HOST $USER $PASSWD "cd $DEPLOY_PATH && $CLEAN_CMD"
    fi
    Print $LOG_NOTICE "deploy online module succ" 
}

print_help()
{
    echo "samples:"
    echo "----------------------------------------------------------------------------------------------"
    echo "$0 ftp://xxx.tar.gz 172.161.1.1 work 123456 qa/se-ci se-ci" 
    echo "$0 ftp://xxx.tar.gz 172.161.1.1 work 123456 qa/naotu naotu tomcat.sh 8280" 
    echo "----------------------------------------------------------------------------------------------"
}

Main() 
{
    #echo $#
    echo $@
    if [ $# -ne 6 -a $# -ne 7 -a $# -ne 8 ]
    then
        print_help
        exit 0
    fi
    wget_path=$1
    HOST=$2
    USER=$3
    PASSWD=$4
    DEPLOY_PATH=$5
    MODULE=$6
    DEPLOY_SCRIPT=$7
    DEPLOY_PORT=$8

    check_host
    init_host
    wget_file $wget_path
    unzip_package
    deploy_online_module
}

Main $@
