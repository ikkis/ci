#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file main.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

LOCAL_TEST="$(readlink -f $(dirname $(readlink -f $0))/../)"
LOCAL_TEST_BIN="$LOCAL_TEST/bin"

. $LOCAL_TEST_BIN/bootstrap.sh

start_path="$(pwd)"

##执行case
export PYTHONPATH="$LOCAL_TEST/":$PYTHONPATH
echo "PYTHONPATH : $PYTHONPATH"

cd "$start_path"
python  "$LOCAL_TEST_BIN"/main.py "$@"
#../frame/tools/python27/bin/python "$(dirname "$0")"/main.py "$@"
