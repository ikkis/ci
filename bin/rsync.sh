#!/bin/sh
LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh
deploy_online_module()
{
    DEPLOY_TIME=`date +"%Y%m%d%H%M%S"`
    DEPLOY_ROOT=`dirname $DEPLOY_PATH`
    Print $LOG_NOTICE "deploy online module start"
    local_cmd "echo 'APP_MODE=\"$APP_MODE\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_HOST=\"$HOST\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_ROOT=\"$DEPLOY_ROOT\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_PATH=\"$DEPLOY_PATH\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_PORT=\"$DEPLOY_PORT\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_TEAM=\"$RESOURCE_SERVER_TEAM\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_NAME=\"$RESOURCE_SERVER_NAME\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'SERVER_DOMAIN=\"$RESOURCE_SERVER_DOMAIN/$RESOURCE_SERVER_URI\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'DEPLOY_TIME=\"$DEPLOY_TIME\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"

    local_cmd cd ~/cidir/$MODULE/$MODULE
    if [ "$RESOURCE_SERVER_NO_CLUDE""x" == "x"  ]; then
        if [ "$RESOURCE_SERVER_INCLUDE""x" != "x" ]; then
           RESOURCE_SERVER_INCLUDE=`echo $RESOURCE_SERVER_INCLUDE | sed -e 's/ /|/g' | sed -e 's/,/|/g'`
           CLEAN_CMD='rm -rf `ls | egrep -v "('$RESOURCE_SERVER_INCLUDE')"`' 
           local_cmd $CLEAN_CMD 
        fi
 
        if [ "$RESOURCE_SERVER_EXCLUDE""x" != "x" ]; then
           RESOURCE_SERVER_EXCLUDE=`echo $RESOURCE_SERVER_EXCLUDE | sed -e 's/,/ /g'`
           local_cmd "rm -rf $RESOURCE_SERVER_EXCLUDE"
        fi
    fi

    local_cmd "rsync -cvzrtopg --delete ~/cidir/$MODULE/$MODULE/ $HOST::$RESOURCE_SERVER_PATH 1>/dev/null"
    if [ $? -ne 0 ]
    then
        local_cmd "echo 'DEPLOY_STATUS=4' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
        local_cmd "echo 'DEPLOY_MSG=\"rsync fail\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
        local_cmd "cd ~/cidir/$MODULE/$MODULE/$CI_PATH; sh bin/monitor.sh"
        Print $LOG_FATAL "deploy error"
        exit 255
    fi
    version_check
    if [ $? -ne 0 ]
    then
        local_cmd "echo 'DEPLOY_STATUS=4' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
        local_cmd "echo 'DEPLOY_MSG=\"cdn check fail\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
        local_cmd "cd ~/cidir/$MODULE/$MODULE/$CI_PATH; sh bin/monitor.sh"
        Print $LOG_FATAL "deploy error"
        exit 255
    fi

    local_cmd "echo 'DEPLOY_STATUS=2' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "echo 'DEPLOY_MSG=\"rsync success\"' >> ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION"
    local_cmd "cd ~/cidir/$MODULE/$MODULE/$CI_PATH ;sh bin/monitor.sh"
    Print $LOG_NOTICE "deploy online module succ" 
}

version_check()
{
    [ "$RESOURCE_SERVER_DOMAIN""x" == "x" ] && return
    VERSION_PATH=`dirname $CI_OUTPUT_VERSION`
    TMP_PATH=".tmp"
    local_cmd "mkdir -p  ~/cidir/$MODULE/$MODULE/$TMP_PATH/$VERSION_PATH"
    int=1
    while(( $int<= 20 ))
    do
        local_cmd " curl $RESOURCE_SERVER_DOMAIN/$RESOURCE_SERVER_URI/$CI_OUTPUT_VERSION > ~/cidir/$MODULE/$MODULE/$TMP_PATH/$CI_OUTPUT_VERSION 2>/dev/null"
        verify_file ~/cidir/$MODULE/$MODULE/$CI_OUTPUT_VERSION ~/cidir/$MODULE/$MODULE/$TMP_PATH/$CI_OUTPUT_VERSION 
        [ $? -eq 0 ] && Print $LOG_NOTICE "check cdn success." && return 0 
        let "int++"
        sleep 5
    done
    return 1
}

wget_file()
{
    wget_file=$1
    local_cmd cd ~/cidir/$MODULE && rm -rf * && wget $wget_file 2>/dev/null 
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "wget file error"
        exit 255
    fi
}

unzip_package()
{
    baseName=`basename $wget_file`

    local_cmd cd ~/cidir/$MODULE && tar -zvxf $baseName 1>/dev/null
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "unzip package error"
        exit 255
    fi
}

init_host()
{
    local_cmd mkdir -p ~/cidir/$MODULE
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "init host error"
        exit 255
    fi
}

print_help()
{
    echo "samples:"
    echo "----------------------------------------------------------------------------------------------"
    echo "$0 ftp://xxx.tar.gz 172.161.1.1 /home/work/www/lianjia-web lianjia-web " 
    echo "$0 ftp://xxx.tar.gz 172.161.1.1 /home/work/www/bs-search bs-search bin/searchd " 
    echo "----------------------------------------------------------------------------------------------"
}

Main() 
{
    #echo $#
    echo $@
    if [ $# -ne 4 -a $# -ne 5 ]
    then
        print_help
        exit 0
    fi
    wget_path=$1
    HOST=$2
    DEPLOY_PATH=$3
    MODULE=$4
    DEPLOY_PORT=$5

    init_host
    wget_file $wget_path
    unzip_package
    deploy_online_module
}



Main $@
