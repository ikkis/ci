#!/bin/sh
source ~/.bash_profile
date=`date +"%Y%m%d"`
ROOT=$HOME
WORKSPACE=$ROOT/local

EXCLUDE="--exclude=*.sock --exclude=*.pid  --exclude=*.log  --exclude=mysql --exclude=logs"

function master(){
   cd ${ROOT}
   HOST="172.16.3.147"
   rsync -avz  ${EXCLUDE}  work@${HOST}:/home/work/local /home/work
   rsync -avz  work@${HOST}:/home/work/seal /home/work
   rsync -avz  work@${HOST}:/home/work/opbin /home/work
}

function init(){
   cd ${ROOT}
   HOST="172.30.13.74"
   USER="shixiaoqiang"
   rsync -avz $USER@${HOST}:/home/$USER/local /home/work
   rsync -avz $USER@${HOST}:/home/$USER/opbin /home/work
   rsync -avz $USER@${HOST}:/home/$USER/seal /home/work
}

function slave(){
   cd ${ROOT}
   HOST="172.30.13.74"
   USER="shixiaoqiang"
   rsync -avz ${EXCLUDE} $USER@${HOST}:/home/$USER/local /home/work
   rsync -avz  $USER@${HOST}:/home/$USER/opbin /home/work
   rsync -avz  $USER@${HOST}:/home/$USER/seal /home/work
}

case $1 in
    "init") echo "$0 init"
            init 
    ;;
    "slave") echo "I am slave, start..."
            slave 
    ;;
    "master") echo "I am master, start... "
           master
    ;;
    *) echo "help: $0 < Who am i >"
    ;;
esac
exit 0
