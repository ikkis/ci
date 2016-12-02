#!/bin/sh
LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

function fe_package(){
    local_cmd rm -rf $LOCAL_OUTPUT_TMP_PATH/$MODULE
    local_cmd mkdir -p $LOCAL_OUTPUT_TMP_PATH/$MODULE 
    local_cmd cd $LOCAL_WORKSPACE

    if [ -f ./online.sh  ] ; then
        local_cmd sh ./online.sh  "./"  "$LOCAL_OUTPUT_TMP_PATH/$MODULE" 
    else
        local_cmd febuild online -p "./" -r "$LOCAL_OUTPUT_TMP_PATH/$MODULE"
    fi
    local_cmd cd $LOCAL_OUTPUT_TMP_PATH
    for PACKAGE in $BUILD_PACKAGE
    do
        local_cmd mkdir -p $MODULE/$CI_PATH
        local_cmd cp -rf $LOCAL_WORKSPACE/$CI_PATH/* $MODULE/$CI_PATH
        local_cmd tar cvzf ${MODULE}_${PACKAGE}.tar.gz $MODULE
    done
}

case $1 in 
    "start") echo "$0 start"
            fe_package 
    ;;
    "stop") echo "$0 stop"
    ;;
    "clean") echo "$0 clean"
    ;;
esac
exit 0



