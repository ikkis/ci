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


LOCAL_TEST="$(readlink -f $(dirname $(readlink -f $0))/../)"
LOCAL_TEST_BIN=$LOCAL_TEST/bin
. $LOCAL_TEST_BIN/bootstrap.sh
WORKSPACE=$HOME
. ./modules.ini

merge(){
    module=$1
    [ "$module""x" == "x" ] && return
    echo "[$module] start..."

    local_cmd rm -rf $WORKSPACE/$module
    local_cmd git clone git@git.lianjia.com:$module.git $WORKSPACE/$module
    echo "git clone git@git.lianjia.com:$module.git $WORKSPACE/$module"
    local_cmd cd $WORKSPACE/$module

    local_cmd git checkout master
    local_cmd git pull 
    branchs=`git branch -a | grep -v master|sed -e 's/remotes\/origin\///'`
    for branch in $branchs 
    do
        local_cmd git checkout $branch
        local_cmd git pull 
        git merge master
        RETVAL=$?
        [ $RETVAL -gt 0 ] && 
            Print $LOG_FATAL "merge [$module : $branch] merge failed!" && 
            fail="$fail $module:$branch" && 
            local_cmd git reset --hard && 
            continue
    
        git push
        [ $RETVAL -gt 0 ] && 
            Print $LOG_FATAL "merge [$module : $branch] merge failed!" && 
            fail="$fail $module:$branch" && 
            local_cmd git reset --hard && 
            continue
        finish="$finish $module:$branch"
    done
    echo "[$module] .........................end"
}

auto_merge(){
    finish=""
    fail=""
    for mod in $modules
    do
        [ $mod"x" == "x" ] && continue
        module=`echo $mod | awk -F":" '{print $1}'`
        branch=`echo $mod | awk -F":" '{print $2}'`
        merge $module
        RETVAL=$?
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "merge master [$module] failed!"  && continue
    done  
    [ ! "$fail""x"  == "x"  ] && Print $LOG_FATAL "ci rsync fail: [ $fail ]"
    Print $LOG_NOTICE "ci rsync succ: [ $finish ]"
}

main(){
  auto_merge
}

main
