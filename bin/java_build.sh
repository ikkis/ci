#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file mvn_test.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

source ~/.bash_profile
LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"
. $LOCAL_TEST_BIN/bootstrap.sh

case $1 in 
    "start") echo "$0 start"
            mvn_package 
    ;;
    "stop") echo "$0 stop"
    ;;
    "clean") echo "$0 clean"
    ;;
esac
exit 0
