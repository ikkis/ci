#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2015 linjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @file run.sh
# * @author shixiaoqiang@lianjia.com
# * @date 2015/04/21/ 10:00:00
# * @version $Revision: 1.0 $ 
# * @brief 
# *  
# **/

SSHBIN=sshpass

LOG_FATAL=1
LOG_WARNING=2
LOG_NOTICE=4
LOG_TRACE=8
LOG_DEBUG=16
LOG_LEVEL_TEXT=(
    [1]="FATAL"
    [2]="WARNING"
    [4]="NOTICE"
    [8]="TRACE"
    [16]="DEBUG"
)

TTY_FATAL=1
TTY_PASS=2
TTY_TRACE=4
TTY_INFO=8
TTY_MODE_TEXT=(
    [1]="[ FATAL ]"
    [2]="[ WARNING ]"
    [4]="[ NOTICE ]"
    [8]="[ TRACE ]"
    [16]="[ DEBUG ]"
)

#0  OFF  
#1  高亮显示  
#4  underline  
#5  闪烁  
#7  反白显示  
#8  不可见 

#30  40  黑色
#31  41  红色  
#32  42  绿色  
#33  43  黄色  
#34  44  蓝色  
#35  45  紫红色  
#36  46  青蓝色  
#37  47  白色 
TTY_MODE_COLOR=(
    [1]="1;31"    
    [2]="1;32"
    [4]="0;36"    
    [8]="1;33"
)


##! @BRIEF: print info to tty & log file
##! @IN[int]: $1 => tty mode
##! @IN[string]: $2 => message
##! @RETURN: 0 => sucess; 1 => failure
function Print()
{
    local tty_mode=$1
    local message="$2"

    local time=`date "+%m-%d %H:%M:%S"`

    CONF_LOG_PATH=$HOME"/var"
    CONF_LOG_FILE=$CONF_LOG_PATH"/${MODULE}_build_trace.log"
    mkdir -p $CONF_LOG_PATH 

    echo "${LOG_LEVEL_TEXT[$log_level]}: $time: ${MODULE} * $$ $message" >> ${CONF_LOG_FILE}
    echo -e "\e[${TTY_MODE_COLOR[$tty_mode]}m${TTY_MODE_TEXT[$tty_mode]} ${message}\e[m"
    return $?
}

build_package()
{
    BUILD_SCRIPT=$1
    DEFAULT_PACKAGE="src"

    #clean
    local_cmd rm -rf $LOCAL_OUTPUT_PATH 
    local_cmd rm -rf $LOCAL_OUTPUT_TMP_PATH 

    #start

    
    local_cmd cd $LOCAL_WORKSPACE
 
    echo "MODULE=\"$MODULE\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "CI_PATH=\"${CI_PATH}\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "CI_HOST=\"${CI_HOST}\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "BUILD=\"${JOB_NAME}\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "BUILD_HOST=\"${BUILD_HOST}\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "BUILD_NUM=\"${BUILD_NUMBER}\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "PACKAGE=\"$DEFAULT_PACKAGE\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    echo "SERVER_TEAM=\"$SERVER_TEAM\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
    for gitPath in `find -name .git | sed -e 's/.git//' | sed -e 's/$//'`
    do
        
        local_cmd cd $gitPath
        #BRANCH=`git rev-parse --abbrev-ref HEAD 2>/dev/null`
        BRANCH=`git describe --contains --all HEAD 2>/dev/null | sed -e 's|remotes/origin/||'`
        VERSION=`git log -1 --pretty=format:"%H" 2>/dev/null`
        COMMITER=`git log -1 --pretty=format:"%an" 2>/dev/null`
        EMAIL=`git log -1 --pretty=format:"%ae" 2>/dev/null`
        COMMENT=`git log -1 --pretty=format:"%s" 2>/dev/null`
        COMMITTIME=`git log -1 --pretty=format:"%ad" --date=iso 2>/dev/null`
        PARENT=`git log -1 --pretty=format:"%P" 2>/dev/null`
        REPOSITORY=`git remote -v 2>/dev/null | head -n1 | awk -F"\t" '{print $2}' | awk -F" " '{print $1}'`
        tag=`echo ${gitPath}| sed -e 's/^\.\///' | sed -e 's/\//_/g'`
        PROJECT=`echo $REPOSITORY | sed -e 's/:/\//' |  sed -e 's/git@/http:\/\//' | sed -e 's/\.git//'` 
        echo "${tag}PROJECT=\"$PROJECT\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}CLONE=\"$REPOSITORY\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}BRANCH=\"$BRANCH\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}COMMIT=\"$VERSION\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}COMMITER=\"$COMMITER\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}EMAIL=\"$EMAIL\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}COMMENT=\"$COMMENT\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}PARENT=\"$PARENT\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        echo "${tag}COMMIT_TIME=\"$COMMITTIME\"" >> $LOCAL_WORKSPACE/$CI_OUTPUT_VERSION
        local_cmd cd -
    done 

    FILES=`ls`
    local_cmd rm -rf $LOCAL_OUTPUT_TMP_PATH"/"$MODULE
    local_cmd mkdir -p $LOCAL_OUTPUT_TMP_PATH"/"$MODULE
    local_cmd cp -ar $FILES $LOCAL_OUTPUT_TMP_PATH"/"$MODULE
    local_cmd cd $LOCAL_OUTPUT_TMP_PATH
    local_cmd find ./ -name ".git"|xargs -i rm -rf {}
    local_cmd tar cvzf $MODULE"_src.tar.gz" $MODULE > /dev/null
    #clean
    local_cmd cd $LOCAL_WORKSPACE

    if [ $BUILD_SCRIPT"x" != "x" ]; then
       if [ $BUILD_HOST"x" == "x" ]; then
          #build
          local_cmd cd $CI_PATH 
          local_cmd sh ./bin/$BUILD_SCRIPT stop
          local_cmd sh ./bin/$BUILD_SCRIPT start
       else
          BUILD_PATH="/home/$BUILD_USER/builds/"$MODULE 
          file=$LOCAL_OUTPUT_TMP_PATH/${MODULE}_${DEFAULT_PACKAGE}.tar.gz
          $LOCAL_TEST_BIN/deploy.sh  ftp://`hostname -i`$file  $BUILD_HOST $BUILD_USER $BUILD_PASSWD $BUILD_PATH $MODULE $BUILD_SCRIPT
          RETVAL=$?
           [ $RETVAL -gt 0 ] && Print $LOG_FATAL "build error: [ $BUILD_HOST ] failed!" && exit $RETVAL
          local_cmd cd $LOCAL_OUTPUT_TMP_PATH;  wget ftp://$BUILD_HOST/$BUILD_PATH/$CI_OUTPUT_TMP_PATH/*.tar.gz 2>/dev/null
       fi
    fi
    local_cmd mkdir -p $LOCAL_OUTPUT_PATH
    local_cmd mv $LOCAL_OUTPUT_TMP_PATH/*.tar.gz $LOCAL_OUTPUT_PATH
}

function mvn2tar_package(){
     SERVER_NAME=$1 
     PACKAGE=$2
     WAR=$3

     [ ! -f $WAR  ]  && echo "Error: $WAR not Exist." && return
     WAR_PATH=`dirname $WAR`
     WAR_NAME=`echo $WAR | awk -F"/" '{print $NF}'`
     local_cmd cd $WAR_PATH
     local_cmd rm -rf $SERVER_NAME                                                   
     local_cmd unzip $WAR_NAME -d $SERVER_NAME                                         

     #pom
     [ -f $LOCAL_WORKSPACE/pom.xml  ] && 
         local_cmd cp -rf $LOCAL_WORKSPACE/pom.xml $SERVER_NAME 
     #ci 
     [ -d $LOCAL_WORKSPACE/$CI_PATH ] && 
         local_cmd mkdir -p $SERVER_NAME/$CI_PATH && 
         local_cmd cp -rf $LOCAL_WORKSPACE/$CI_PATH/* $SERVER_NAME/$CI_PATH && 
         echo "PACKAGE=\"$PACKAGE\"" >> $SERVER_NAME/$CI_OUTPUT_VERSION &&
         echo "SERVER_NAME=\"$SERVER_NAME\"" >> $SERVER_NAME/$CI_OUTPUT_VERSION

     #resource
     [ -d $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH ] && 
          local_cmd mkdir -p $SERVER_NAME/$BUILD_RESOURCE_OUTPUT_PATH &&
          local_cmd rm -rf $SERVER_NAME/$BUILD_RESOURCE_OUTPUT_PATH/* &&
          local_cmd cp -rf $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH/* $SERVER_NAME/$BUILD_RESOURCE_OUTPUT_PATH/
          [ -f $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH/cdnResource.json ] && 
              local_cmd cp -f $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH/cdnResource.json $SERVER_NAME/WEB-INF/classes/

     local_cmd tar cvzf ${SERVER_NAME}_${PACKAGE}.tar.gz $SERVER_NAME                            
     local_cmd mv ${SERVER_NAME}_${PACKAGE}.tar.gz $LOCAL_OUTPUT_TMP_PATH/
     local_cmd cd -                           
}

function mvn_package(){
    [ "$BUILD_OUTPUT_NAME_EXTENSION""x" == "x" ] && BUILD_OUTPUT_NAME_EXTENSION="war"
    BUILD_OUTPUT_NAME_EXTENSION=`$BUILD_OUTPUT_NAME_EXTENSION | sed -e 's/|/ /' | sed -e 's/,/ /'`

    for PACKAGE in $BUILD_PACKAGE
    do  
        local_cmd cd $LOCAL_WORKSPACE
        if [ "$UNIT_TEST""x" == "x" ] ; then 
            local_cmd mvn clean package -P$PACKAGE -U -Dmaven.test.skip=true                      
        else
            local_cmd mvn clean package -P$PACKAGE -U -Dtest="$UNIT_TEST" 
        fi
        [ "$BUILD_OUTPUT_PATH""x" != "x" ] && cd $BUILD_OUTPUT_PATH
        for item in $BUILD_OUTPUT_NAME_EXTENSION
        do 
           WARS=`echo $WARS``find -name "*" | egrep  -e "\.$item$"`
        done
        WARS_COUNT=`echo "$WARS" | wc -l`
        for WAR in $WARS 
        do
            [ $WARS_COUNT -gt 1 ]  && 
                SERVER_NAME=`echo $WAR |sed -e 's/-0.0.1-SNAPSHOT//'|awk -F"/" '{print $NF}'|awk -F"." '{print $1}'`
            mvn2tar_package $SERVER_NAME $PACKAGE $WAR
        done                                                                                  
    done
}

function fe_package(){
    [ ! -d $LOCAL_WORKSPACE/$BUILD_RESOURCE_PATH ] && return
    local_cmd rm -rf $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH
    local_cmd mkdir -p $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH

    local_cmd cd $LOCAL_WORKSPACE/$BUILD_RESOURCE_PATH 
    if [ -f ./online.sh  ] ; then
        local_cmd sh ./online.sh  "./"  "$LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH"  $BUILD_RESOURCE_MODULE $LOCAL_WORKSPACE/$BUILD_RESOURCE_TEMPLATE_PATH
    elif [ -f ./build.sh  ] ; then
        local_cmd sh ./build.sh  "./"  "$LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH" 
    else
        local_cmd febuild online -p "./" -r "$LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH"
    fi
}

function php_package(){
    local_cmd cd $LOCAL_WORKSPACE
    FILES=`ls`
    PACKAGE="prod"
    local_cmd rm -rf $LOCAL_OUTPUT_TMP_PATH"/"$MODULE
    local_cmd mkdir -p $LOCAL_OUTPUT_TMP_PATH"/"$MODULE
    local_cmd cp -ar $FILES $LOCAL_OUTPUT_TMP_PATH"/"$MODULE

    local_cmd cd $LOCAL_OUTPUT_TMP_PATH
    local_cmd find ./ -name ".git"|xargs -i rm -rf {}
     #resource
     [ -d $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH ] && 
          local_cmd mkdir -p $MODULE/$BUILD_RESOURCE_OUTPUT_PATH &&
          local_cmd rm -rf $MODULE/$BUILD_RESOURCE_OUTPUT_PATH/* &&
          local_cmd cp -rf $LOCAL_OUTPUT_TMP_PATH/$BUILD_RESOURCE_OUTPUT_PATH/* $MODULE/$BUILD_RESOURCE_OUTPUT_PATH/

    local_cmd tar cvzf $MODULE"_${PACKAGE}.tar.gz" $MODULE > /dev/null
}

java_deploy()
{
    JAVA_SERVER_NAME=$1
    JAVA_PACKAGE=$2
    JAVA_OUTPUT_PATH=$3
    JAVA_HOST=$4
    JAVA_PATH=$5
    JAVA_PORT=$6

    file=$JAVA_OUTPUT_PATH/${JAVA_SERVER_NAME}_${JAVA_PACKAGE}.tar.gz
    file="ftp://$JAVA_HOST"$file

    hosts=`echo $DEPLOY_HOST | sed -e 's/:/ /g'| sed -e 's/;/ /g'`
    finish=""
    for host in $hosts
    do 
    	local_cmd sh $LOCAL_TEST_BIN/deploy.sh $file $host $DEPLOY_USER $DEPLOY_PASSWD $JAVA_PATH $JAVA_SERVER_NAME $DEPLOY_SCRIPT $JAVA_PORT
        RETVAL=$?
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "deploy error: [$host] failed!" && exit $RETVAL
        
        finish="$finish $host"
    done
    Print $LOG_NOTICE "deploy succ: [ $finish ]"
}

deploy_package()
{
    OUTPUT_PATH=$1
    PACKAGE=$2
    HOST=$3
    [ $PACKAGE"x" == "x" ] && PACKAGE="src"    
    [ $OUTPUT_PATH"x" == "x" ] && OUTPUT_PATH=$LOCAL_OUTPUT_PATH 
    [ $HOST"x" == "x" ] && HOST=`hostname -i`


    SERVER_COUNT=`echo $SERVER_NAME | awk -F";" '{print NF}'`
    [ $SERVER_COUNT -eq 1  ] &&
        fe_deploy  $SERVER_NAME $PACKAGE $OUTPUT_PATH $HOST $RESOURCE_SERVER_PATH  $RESOURCE_SERVER_PORT &&
        java_deploy  $SERVER_NAME $PACKAGE $OUTPUT_PATH $HOST $SERVER_PATH $SERVER_PORT && 
        return
    
    SERVER_NAME=`echo $SERVER_NAME | sed -e 's/;/ /g'`
    for SERVER in  $SERVER_NAME
    do
        SNAME=`echo $SERVER | awk -F":" '{print $1}'` 
        SPORT=`echo $SERVER | awk -F":" '{print $2}'`
        [ "$SPORT""x" == "x" ] && SPORT=$SERVER_PORT

        #覆盖的方式，最后部署的服务进行测试 
        SERVER_PATH=$SERVER_ROOT/$SNAME
        fe_deploy  $SNAME $PACKAGE $OUTPUT_PATH $HOST $RESOURCE_SERVER_PATH $RESOURCE_SERVER_PORT &&
        java_deploy  $SNAME $PACKAGE $OUTPUT_PATH $HOST $SERVER_PATH $SPORT 
    done
}

online_package()
{
    OUTPUT_PATH=$1
    PACKAGE=$2
    HOST=$3
    DOMAIN=$4
    TOKEN=$5
    [ $OUTPUT_PATH"x" =="x" ] && OUTPUT_PATH=$LOCAL_ARCHIVE_PATH
    [ $PACKAGE"x" == "x" ] && PACKAGE="prob"
    [ $HOST"x" == "x" ] && HOST=`hostname -i`
    [ $DOMAIN"x" == "x"] && return
    [ $TOKEN"x" == "x"] && return

    SERVER_COUNT=`echo $SERVER_NAME | awk -F";" '{print NF}'`
    [ $SERVER_COUNT -eq 1  ] &&
        file="ftp://$HOST$OUTPUT_PATH/${SERVER_NAME}_${PACKAGE}.tar.gz"
        local_cmd "/usr/bin/distrsync --url $file --module $DOMAIN --access-token $TOKEN"
        return

    SERVER_NAME=`echo $SERVER_NAME | sed -e 's/;/ /g'`
    for SERVER in  $SERVER_NAME
    do
        SNAME=`echo $SERVER | awk -F":" '{print $1}'`
        file="ftp://$HOST$OUTPUT_PATH/${SNAME}_${PACKAGE}.tar.gz"
        local_cmd "/usr/bin/distrsync --url $file --module $DOMAIN --access-token $TOKEN"
    done
    return 0
}

local_test()
{
    cases=$@
    if [ "$cases""a" != "a" ] ; then
        echo "run test $cases"
    elif [ $TEST_CASE"x" != "x" ]; then
        cases=$TEST_CASE
        echo "run test $cases"
    else
        echo "empty test"
        return 0
    fi
    finish=""
    hosts=`echo $DEPLOY_HOST | sed -e 's/:/ /g' | sed -e 's/;/ /g' `
    for host in $hosts
    do
        local_cmd sh $LOCAL_TEST_BIN/main.sh $cases
        RETVAL=$?
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "run test error: [$host] failed!" && exit $RETVAL
        finish="$finish $host"
    done
    Print $LOG_NOTICE "run test succ: [ $finish ]"
    return 0
}

remote_test()
{
    cases=$@
    if [ "$cases""a" != "a" ] ; then
    	echo "run test $cases"
    elif [ $TEST_CASE"x" != "x" ]; then
        cases=$TEST_CASE
    	echo "run test $cases"
    else
        echo "empty test"
        return 0
    fi
    finish=""
    hosts=`echo $DEPLOY_HOST | sed -e 's/:/ /g' | sed -e 's/;/ /g' `
    for host in $hosts
    do 
        remote_cmd $host $DEPLOY_USER $DEPLOY_PASSWD "cd $SERVER_PATH/$CI_PATH; sh bin/main.sh $cases"
        RETVAL=$?
        loadCoverage
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "run test error: [$host] failed!" && exit $RETVAL
        finish="$finish $host"
    done
    Print $LOG_NOTICE "run test succ: [ $finish ]"
    return 0
}

loadCoverage()
{
   [ "$JACOCO_COVERAGE""x" == "x" ] && return
   [ "$DEPLOY_SCRIPT""x" != "tomcat.sh""x" ] && return
   [ "$JAVA_OPTS""x" == "x" ] && return

   local_cmd cd $LOCAL_WORKSPACE
   local_cmd ant -file $JACOCO_BUILD_FILE dump -Dserver_ip="$JACOCO_HOST" -Dserver_port=$JACOCO_PORT -DjacocoexecPath=$JACOCO_OUTPUT_EXEC 
   local_cmd nohup $CI_PATH/bin/sonar.sh &
}

ini_replace(){

   fileName=$1
   match=$2
   replacement=$3
   [ $replacement"x" == "x" ] && return
   files_all=`find -name ${fileName}`
   [ "$files_all""x"  == "x" ] && return
   files=`grep -H "$match" $files_all | awk -F":" '{print $1}' | uniq`
   [ "$files""x"  == "x" ] && return
   for subject in $files
   do
       [ -f $subject ] || continue
       timestamp=`date "+%Y%m%d%H%M%S"`
       cp -f $subject  $subject"."$timestamp
       Print $LOG_NOTICE "[$subject] $match:$replacement" 
       sed -i 's/'$match'/'$replacement'/g' $subject 
   done 
}

ini_check(){
   key=$1
   ismust=$2
   if [ "${!key}""x" == "x" ];then
        if [ "$ismust""x" != "x" ]; then
	    Print $LOG_FATAL "$key must required!"
            exit 255
        fi
   fi
   export $key="${!key}"

   RETVAL=$?
   [ $RETVAL -gt 0 ] && Print $LOG_FATAL "Error ini check: $key=${!key}"  && exit $RETVAL
   Print $LOG_NOTICE "ini check: $key=${!key}"
   return 0 
}

local_cmd(){
    cmd=$@
    eval $cmd
    [ $? -gt 0 ] && Print $LOG_FATAL "run cmd error: $cmd"  && exit 255
    Print $LOG_NOTICE "run cmd succ: $cmd"
    return 0 
}

remote_cmd()
{
    host=$1
    user=$2
    passwd=$3
    cmd=$4
    $SSHBIN -p $passwd ssh $user@$host -p $DEPLOY_SSHPORT "export APP_MODE=$APP_MODE;$cmd"
    if [ $? -ne 0 ]
    then
        Print $LOG_FATAL "run cmd error: sshpass -p $passwd ssh $user@$host -p $DEPLOY_SSHPORT $cmd"
        return 255
    else
        Print $LOG_NOTICE "run cmd succ: sshpass -p $passwd ssh $user@$host -p $DEPLOY_SSHPORT $cmd"
    fi
    return 0 
}

fe_deploy()
{
    FE_SERVER_NAME=$1
    FE_PACKAGE=$2
    FE_OUTPUT_PATH=$3
    FE_HOST=$4
    FE_PATH=$5
    FE_PORT=$6

    [ "$FE_PATH""x" == "x" ] && return
 
    file=$FE_OUTPUT_PATH/${FE_SERVER_NAME}_${FE_PACKAGE}.tar.gz
    file="ftp://$FE_HOST"$file
    
    [ "$RESOURCE_DEPLOY_HOST""x" == "x" ] && return
    hosts=`echo $RESOURCE_DEPLOY_HOST | sed -e 's/:/ /g'| sed -e 's/;/ /g'`
    finish=""

    for host in $hosts
    do
    	local_cmd sh $LOCAL_TEST_BIN/rsync.sh $file $host $FE_PATH $FE_SERVER_NAME $FE_PORT 
        RETVAL=$?
        [ $RETVAL -gt 0 ] && Print $LOG_FATAL "deploy error: [$host] failed!" && exit $RETVAL
        
        finish="$finish $host"
    done
    Print $LOG_NOTICE "deploy succ: [ $finish ]"
}

verify_file()
{
   [ "$2""x" == "x"  ] && Print $LOG_FATAL "Error: two files needed" && exit 1
   [ ! -f $1  ]  && Print $LOG_FATAL "Error: [$1] is not a file" && exit 1
   [ ! -f $2  ]  && Print $LOG_FATAL "Error: [$2] is not a file" && exit 1 

   md5_1=`md5sum $1 | awk -F" " '{print $1}'`
   md5_2=`md5sum $2 | awk -F" " '{print $1}'`

   [ "$md5_1" != "$md5_2" ] && Print $LOG_FATAL "Warning: [$1:$2] not same" && return 1
    Print $LOG_NOTICE " [ $1:$2] same"
   return 0
}

monitor_post()
{
   data=$@
   [ "$MONITOR_SERVER""x" == "x" ] && return
   curl -d"$data" $MONITOR_SERVER
}
