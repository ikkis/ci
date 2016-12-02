#!/bin/bash
#!/bin/sh
#/*****************************************************************
# * 
# * Copyright (c) 2016 linjia.com, Inc. All Rights Reserved
# * 
# ****************************************************************/

#/**
# * @file install.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2016/08/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_NAME="ci"
LOCAL_TEST="$(readlink -f $(dirname $(readlink -f $0))/)"
LOCAL_TEST_BIN="$LOCAL_TEST/bin"
LOCAL_TEST_CONF="$LOCAL_TEST/conf"
LOCAL_TEST_TEST="$LOCAL_TEST/test"

function help(){
    echo "$0 <target>"
    exit 0
}

function init(){
   target=$1
   if [ -d $target/$LOCAL_TEST_NAME ] ; then 
       cp -rf $LOCAL_TEST_BIN/* $target/$LOCAL_TEST_NAME/bin/ 
       echo "[$target] update [$LOCAL_TEST_NAME]...success"  
   else
       mkdir -p $target/$LOCAL_TEST_NAME
       cp -rf $LOCAL_TEST_BIN $target/$LOCAL_TEST_NAME 
       cp -rf $LOCAL_TEST_CONF $target/$LOCAL_TEST_NAME 
       cp -rf $LOCAL_TEST_TEST $target/$LOCAL_TEST_NAME 
       echo "[$target] init [$LOCAL_TEST_NAME]...success"  
   fi
}

function main(){
    [ $1"x" == "x" ] && help
    init $1
}

main $@
