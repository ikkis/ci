#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file release.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2016/11/17/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST_BIN="$(readlink -f $(dirname $(readlink -f $0))/)"

[ $APP_MODE"x" == "x" ] && export APP_MODE="online"
source $LOCAL_TEST_BIN/bootstrap.sh

online_package $LOCAL_ARCHIVE_PATH $DEPLOY_PACKAGE $ARCHIVE_HOST $SERVER_DOMAIN $ONLINE_TOKEN
