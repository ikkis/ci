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

update_ci(){
    module=$1
    branch=$2

    target=$(readlink -f "$WORKSPACE/$module")
    src=$(readlink -f "$LOCAL_TEST")

    [ ! -d $src ] &&  Print $LOG_FATAL "rsync error: [$src] not exist!" && return 255 
    [ ! -d $target ] &&  Print $LOG_FATAL "rsync error: [$target] not exist!" && return 255 
      
    cd $target
    echo "[$target] start..."
    [ "$branch""x" != "x" ] && git checkout $branch  
    if [ $src  != $target  ]; then
       sh $src/install.sh $target 
    fi
    git add $target/ci/bin/*
    git commit -m "qa ci auto update"
    git pull
    git push
    echo "[$target] .........................end"
}

ci_rsync(){
    finish=""
    fail=""
    for mod in $modules
    do
        [ $mod"x" == "x" ] && continue
        module=`echo $mod | awk -F":" '{print $1}'`
        branch=`echo $mod | awk -F":" '{print $2}'`
        update_ci $module $branch
        RETVAL=$?
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "ci_rsync [$module] failed!" && fail="$fail $module" && continue
        finish="$finish $module"
    done  
    [ ! "$fail""x"  == "x"  ] && Print $LOG_FATAL "ci rsync fail: [ $fail ]"
    Print $LOG_NOTICE "ci rsync succ: [ $finish ]"
}

env_rsync(){
   rsync -avz --exclude=*_temp --exclude=*.sock --exclude=*.pid  --exclude=*.log  --exclude=php.ini  work@172.16.3.147:/home/work/local /home/work/
   echo "tb+d32TRmnt7l4bAfslL"
   #host="172.16.4.189"
   host="172.16.5.59"
   rsync -avz --exclude=*_temp --exclude=*.sock --exclude=*.pid  --exclude=*.log --exclude=nginx.conf  --exclude=php.ini  rd@$host:/home/work/local /home/work/
   rsync -avz  --exclude=offline rd@$host:/home/work/se /home/work/
   #rsync -avz  rd@$host:/home/work/opbin /home/work/
   #rsync -avz  --exclude=*.sock --exclude=*.pid rd@$host:/home/work/var/ /home/work/var 
   rsync -avz rd@$host:/home/work/.m2 /home/work/


   host="172.16.4.217"
   rsync -avz --exclude=*_temp --exclude=*.sock --exclude=*.pid  --exclude=*.log --exclude=nginx.conf --exclude=php.ini  rd@$host:/home/work/local /home/work/
   rsync -avz  --exclude=offline rd@$host:/home/work/se-score /home/work/
   rsync -avz  rd@$host:/home/work/opbin /home/work/
   #rsync -avz  --exclude=*.sock --exclude=*.pid rd@$host:/home/work/var/ /home/work/var 

   #iptables -t nat -A PREROUTING -p tcp  --dport 80 -j DNAT --to-destination 172.30.11.202:8008
   rsync -avz --exclude=*.git  shixiaoqiang@172.30.11.202:xts ./
}

ci_rsync
