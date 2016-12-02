#!/bin/bash
#/***************************************************************************
# * 
# * Copyright (c) 2016 lianjia.com, Inc. All Rights Reserved
# * 
# **************************************************************************/

#/**
# * @author shixiaoqiang@lianjia.com
# * @date 2016/09/28/ 10:00:00
# * @version $Revision: 1.0 $
# * 鸣谢：RLA基于时间戳、KEY、VALUE三元组匹配统计和报警模式,吕毅 
# * 鸣谢：Shell邮件发送机制,黄树仁,cp-rd 
# * 鸣谢：JAVA邮件发送格式,吴玲,fn-rd
# * 鸣谢：邮件表格样式微调,董亚杰,link-fe 
# * @Thanks 
# **/

function help(){
    echo "$0 <MODULE> <RULE_NAME> <RULE_RULE_DESC> <APP_MODE> <LOG_FILE> <EMAIL_TO> <TIME_PREG> <KEY_PREG> <VALUE_PREG>"
    return
}
[ $# -lt 9 ] && help && exit 255

MODULE=$1
RULE_NAME=$2
RULE_DESC=$3
APP_MODE=$4
LOG_FILE=$5
EMAIL_TO=$6
TIME_PREG=$7
KEY_PREG=$8
VALUE_PREG=$9
KEY_IGNORE_PREG=${10}
VALUE_IGNORE_PREG=${11}

SERVER_HOST=`hostname -i`
HOST_NAME=`hostname -s`
#MODULE='mysql'
#RULE_NAME='mysql'
#RULE_DESC='数据库慢日志'
#APP_MODE='test'
#LOG_FILE="/home/work/local/mysql/log/mysql-slow.log"
#EMAIL_TO='shixiaoqiang@lianjia.com'

#TIME_PREG='Time: (.+?)'
#KEY_PREG='Query_time:(.+?)'
#VALUE_PREG='^[^#](.+)$'

#TIME_PREG='([0-9]{4}?)-?([0-9]{2}?)-?([0-9]{2}?)[ |-]?([0-9]{2}?):([0-9]{2}?):([0-9]{2}?)'
#KEY_PREG='ERROR (.+?) -'
#VALUE_PREG='- (.+?)$'

[ "$KEY_IGNORE_PREG""x" == "x"  ] && KEY_IGNORE_PREG=' -'
[ "$VALUE_IGNORE_PREG""x" == "x"  ] && VALUE_IGNORE_PREG='SET timestamp=[0-9]*;'
email_format='"'`echo "$EMAIL_TO" | sed -e 's/"//g' | sed -e 's/,/","/g' | sed -e 's/;/","/g'`'"'
beat=3600

monitor_post()
{
   monitor_data=$@
   MONITOR_SERVER="http://lts.ci.lianjia.com/api/log"
   curl -d"$monitor_data" $MONITOR_SERVER
}

function logAnalyse(){
   content="$@"
   counter=0
   data=""
   mail_content=""
   now_time=`date "+%F %T"`
   while true
   do
       pageInfo=""
       [ "$content""x" == "x" ] && echo "content is empty" && break
       ##根据时间戳分页
       pageCounter=`echo "$content" | egrep -n -e "$TIME_PREG" | wc -l`
       [ $pageCounter -eq 0 ] && echo "pageCounter is 0" && break
       pageBegin=`echo "$content" | egrep -n -e "$TIME_PREG" | head -n1 | awk -F":" '{print $1}'`
       if [ $pageCounter -eq 1 ] ; then
           pageEnd=`echo "$content" | wc -l`
       else
           pageEnd=`echo "$content" | egrep -n -e "$TIME_PREG" | head -n2 | tail -n1 | awk -F":" '{print $1}'`
           pageEnd=$(($pageEnd-1))
       fi
       pageInfo=`echo "$content" | sed -n ''$pageBegin','$pageEnd'p'`
       pageEnd=$(($pageEnd+1))
       content=`echo "$content" | tail -n +$pageEnd`

       echo "pageCounter:"$pageCounter
       echo "pageBegin:"$pageBegin
       echo "pageEnd:"$pageEnd
       echo "pageInfo:\n""$pageInfo"

       ##时间戳
       time_str=`echo "$pageInfo" | head -n1 | egrep -o -e "$TIME_PREG" | sed -e 's/^[^0-9]*//' | sed -e 's/[^0-9]*$//'`
       timestamp=`date -d "$time_str" "+%F %T"`
       [ "$timestamp""x" == "x" ] && 
           time_str=`echo "$time_str" |  sed -e 's/-/ /g'` && 
           timestamp=`date -d "$time_str" "+%F %T"`
       [ "$timestamp""x" == "x" ] && echo "$TIME_PREG not matched" && continue

       ##根据关键词分段
       while true
       do
          sectionInfo=""
          key=""
          value=""
          [ "$pageInfo""x" == "x" ] && echo "pageInfo is empty" && break
          sectionCounter=`echo "$pageInfo" | egrep -n -e "$KEY_PREG" | wc -l`
          [ $sectionCounter -eq 0 ] && echo "sectionCounter is 0" && break
          sectionBegin=`echo "$pageInfo" | egrep -n -e "$KEY_PREG" | head -n1 | awk -F":" '{print $1}'`
          if [ $sectionCounter -eq 1 ] ; then
              sectionEnd=`echo "$pageInfo" | wc -l`
          else
              sectionEnd=`echo "$pageInfo" | egrep -n -e "$KEY_PREG" | head -n2 | tail -n1 | awk -F":" '{print $1}'`
              sectionEnd=$(($sectionEnd-1))
          fi
          sectionInfo=`echo "$pageInfo" | sed -n ''$sectionBegin','$sectionEnd'p'`
          sectionEnd=$(($sectionEnd+1))
          pageInfo=`echo "$pageInfo" | tail -n +$sectionEnd`

          echo "sectionCounter:""$sectionCounter"
          echo "sectionBegin:""$sectionBegin"
          echo "sectionEnd:""$sectionEnd"
          echo "sectionInfo:\n""$sectionInfo"

          ##关键词
          key=`echo "$sectionInfo" | egrep -o -e "$KEY_PREG"`
          [ "$key""x" == "x" ] && echo "$KEY_PREG not matched" && continue
          [ "$KEY_IGNORE_PREG""x" != "x" ] && key=`echo "$key" | sed -e 's/'"$KEY_IGNORE_PREG"'//g'`

          ##键值
          if [ "$VALUE_PREG""x" != "x"  ] ; then
              value=`echo "$sectionInfo" | egrep -o -e "$VALUE_PREG"`
              [ "$value""x" == "x" ] && echo "$VALUE_PREG not matched" && continue
          else
              value="$sectionInfo"
          fi
          [ "$VALUE_IGNORE_PREG""x" != "x" ] && value=`echo "$value" | sed -e 's/'"$VALUE_IGNORE_PREG"'//g'`

          ##去掉空行
          key=`echo "$key" |  sed -e '/^\s*$/d' | sed -e 's/	//g' | sed -e 's/"/\\\"/g'`
          value=`echo "$value" |  sed -e '/^\s*$/d' | sed -e 's/	//g' | sed -e 's/"/\\\"/g'`

          ##格式化回车,否则推送容易失败
          while true
          do
             i=`echo "$key" | wc -l`
             [ $i -eq 1  ] && break
             key=`echo "$key" | sed 'N;s/\n/<br>/g'`
          done
          ##格式化回车,否则推送容易失败
          while true
          do
             i=`echo "$value" | wc -l`
             [ $i -eq 1  ] && break
             value=`echo "$value" | sed 'N;s/\n/<br>/g'`
          done

          #发送到测试服务平台
          monitor_post "module=$MODULE&app_mode=$APP_MODE&server_name=$RULE_NAME&server_host=$SERVER_HOST&host_name=$HOST_NAME&log_desc=$RULE_DESC&log_path=$LOG_FILE&log_key=$key&log_value=$value&email=$EMAIL_TO&log_time=$timestamp" 

          ##格式化邮件表格
          data="$data""<hr/>"
          data="$data""<table border='1px' cellpadding='1' cellspacing='0' bordercolor='#ccc'>"
          data="$data""<tr><td width='10%'>时间:</td><td>""$timestamp""</td></tr>"
          data="$data""<tr><td width='10%'>事件:</td><td>""$key""</td></tr>"
          data="$data""<tr><td width='10%'>定位:</td><td>""$value""</td></tr>"
          data="$data""</table>"

          ##报警计数器
          counter=$(($counter+1))
       done
       len=`expr length "$data"`
       echo "len:"$len
       #[ $len -gt 1000 ] && echo "page too long" && break
   done
   echo "counter:"$counter
   [ $counter -eq 0  ] && echo "counter is 0" && return

   #发送邮件
   mail_content="<META http-equiv=Content-Type content='text/html; charset=UTF-8'>"
   mail_content="$mail_content""<h2>报警数(每小时):$counter, 机器:$SERVER_HOST($HOST_NAME)</h2>"
   mail_content="$mail_content""服务模块:$MODULE, 规则名称:$RULE_NAME <a href='http://lts.ci.lianjia.com/monitor/log?prod_id=$MODULE&server_host=$SERVER_HOST'>查看更多</a>"
   mail_content="$mail_content""$data""<hr/>"
   mail_content="$mail_content""QA日志监控触发时间为 $now_time<br>请联系: shixiaoqiang@lianjia.com"
   echo "$mail_content"
   curl -i -X POST 'http://sms.lianjia.com/lianjia/sms/send' -d '{
                        "version": "1.0",
                        "method": "mail.sent",
                        "group":"seproject",
                        "auth":"nkhwzx76ZJUmCyreuxYrUCcd9S6zM2eS",
                        "params": {"to":['"$email_format"'],
                                "subject":"[LOG监控]'"[$RULE_DESC]""[${APP_MODE}环境]"'",
                                "body":"'"${mail_content}"'"
                            }
                         }'
}

function main(){
        [ ! -f $LOG_FILE ] && echo "Fail: file [$LOG_FILE] not exist!" && exit 255
        #flock -nx 9 || exit 255
        startNum=`cat $LOG_FILE | wc -l`
        while true
        do
                var=""
                var2=""
                spase=0
                newNum=`cat $LOG_FILE | wc -l`
                if [ $startNum -lt  $newNum ] ; then
                       startNum=$(($startNum+1))
                       var=`sed -n ''$startNum','$newNum'p' $LOG_FILE`
                elif [ $newNum -lt  $startNum ] ; then
                       var=`sed -n '1,'$newNum'p' $LOG_FILE`
                fi
                echo "startNum:"$startNum 
                echo "newNum:"$newNum
                logAnalyse "$var"
                startNum=$newNum
                sleep $beat
        done
}
main
