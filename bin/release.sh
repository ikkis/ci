#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file release.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"

[ $APP_MODE"x" == "x" ] && export APP_MODE="prod"
source $LOCAL_TEST_BIN/bootstrap.sh

deploy_package  $LOCAL_ARCHIVE_PATH $DEPLOY_PACKAGE $ARCHIVE_HOST
