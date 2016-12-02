#!/bin/bash                                                                                                                           
workspace="$(readlink -f $(dirname $(readlink -f $0))/)"

function local_cmd(){
    cmd=$@
    echo "$cmd"
    eval "$cmd"
}

function bootstrap(){
  echo 1 > /proc/sys/net/ipv4/ip_forward
  #清理
  local_cmd iptables -F  
  local_cmd iptables -t nat -F  
  local_cmd iptables -t mangle -F  
  local_cmd iptables -X  
  local_cmd iptables -t nat -X  
  local_cmd iptables -t mangle -X  
  local_cmd iptables -P INPUT ACCEPT  
  local_cmd iptables -P OUTPUT ACCEPT  
  local_cmd iptables -P FORWARD ACCEPT

  #开启关联连接
  local_cmd iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  local_cmd iptables -t filter -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  
  #开启本地连接
  local_cmd iptables -t filter -A INPUT -s 127.0.0.1 -j ACCEPT 
  local_cmd iptables -t filter -A OUTPUT -d 127.0.0.1 -j ACCEPT 
  host_ip=`hostname -i`
  local_cmd iptables -t filter -A INPUT -s $host_ip -j ACCEPT 
  local_cmd iptables -t filter -A OUTPUT -d $host_ip -j ACCEPT 

  #开启80端口
  local_cmd iptables -t filter -A INPUT  -p tcp  --dport 80 -j ACCEPT
  #开启22端口
  local_cmd iptables -t filter -A INPUT  -p tcp  --dport 22 -j ACCEPT
  #域名解析53端口
  local_cmd iptables -t filter -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
}

function end(){
  FILTER_TARGET=$1
  [ "$FILTER_TARGET""x" == "ACCEPTx" ] && return

  local_cmd iptables -t filter -A INPUT -j $FILTER_TARGET
  local_cmd iptables -t filter -A OUTPUT -j $FILTER_TARGET
  local_cmd iptables -t filter -A FORWARD -j $FILTER_TARGET
}

function add_filter(){
   filterTarget=$1
   protocol=$2
   dnIp=$3
   dnPort=$4
   
   [ "$dnIp""x" == "x" ] && echo "Error:[$@] add_filter ip is empty!" && return
   #本地默认已经开启，不需要额外制定
   [ "$dnIp""x" == "127.0.0.1""x"  ] && return
   #本地对外开放某个端口
   if [ "$dnIp""x" == "local""x"  ] ; then
       [ "$dnPort""x" == "x" ] && echo "Error:[$@] add_filter port is empty!" && return
       local_cmd iptables -t filter -A  INPUT  -p $protocol  --dport $dnPort -j $filterTarget 
       local_cmd iptables -t filter -A OUTPUT  -p $protocol  --sport $dnPort -j $filterTarget
       return
   fi 

   #外部链接开放
   if ! [[ $dnIp =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]
   then
       echo "Resolving:$dnIp"
       dnIp=`nslookup $dnIp | grep "Address: " | sed -e 's/Address: //'`
       echo "$dnIp"
   #else
       #echo ${BASH_REMATCH[1]}
       #echo ${BASH_REMATCH[2]}
       #echo ${BASH_REMATCH[3]}
       #echo ${BASH_REMATCH[4]}
   fi
   for ip in $dnIp
   do
       unset dport_cmd
       unset sport_cmd
       [ "$dnPort""x" != "x" ] && dport_cmd="--dport $dnPort" && sport_cmd="--sport $dnPort" 
       local_cmd iptables -t filter -A OUTPUT  -p $protocol -d $ip  $dport_cmd -j $filterTarget 
       local_cmd iptables -t filter -A  INPUT  -p $protocol -s $ip  $sport_cmd -j $filterTarget 
   done
}

function add_dnat(){
   protocol=$1 
   dIp=$2
   dPort=$3
   dnIp=$4
   dnPort=$5
   
   [ "$dnPort""x" == "x" ] && echo "Error:[$@] add_dnat port is empty!" && return
   local_cmd iptables -t nat -I OUTPUT -d $dIp -p $protocol --dport $dPort -j DNAT --to $dnIp:$dnPort
}

function deal_conf(){

    [ "$CONF_FILE""x" == "x" ] && return
    [ ! -f $CONF_FILE ] && return
    list=`cat $CONF_FILE | egrep -v "^(\s*#)" | egrep -v "^(\s*)$"`
    for item in $list
    do
        unset dItem
        unset dnItem
        unset dnIp
        unset dnPort
        unset dIp
        unset dPort
        unset protocol
        unset filterTarget

        [ $item"x" == "x" ] && continue
        infoItem=`echo $item | awk -F"@" '{print $1}'`
        filterTarget=`echo $item | awk -F"@" '{print $2}'`

        #Target限制为(ACCEPT、REJECT)
        [ "$filterTarget""x" == "x" ] && filterTarget="ACCEPT"  
        [ "$filterTarget""x" != "ACCEPT""x" ]  && 
            [ "$filterTarget""x" != "REJECT""x" ]  && 
                echo "Error: unknow[$filterTarget],must in (ACCEPT、REJECT)" && 
                continue 

        #空IP过滤，视为全局规则结束遍历
        [ $infoItem"x" == "x" ] && 
            end $filterTarget && 
            echo "Find [$item] end." && 
            break
 
        dItem=`echo $infoItem | awk -F"->" '{print $1}'`
        dnItem=`echo $infoItem | awk -F"->" '{print $2}'`
      
        #非NAT规则,跟进参数调整Target
        [ "$dnItem""x" == "x" ] && dnItem=$dItem 
        [ "$dnItem""x" == "x" ] && return 
        dnIp=`echo $dnItem | awk -F":" '{print $1}'`
        dnPort=`echo $dnItem | awk -F":" '{print $2}'`
        dnProtocol=`echo $dnItem | awk -F":" '{print $3}'`
        [ "$dnProtocol""x" == "x"  ] && dnProtocol="tcp"
        add_filter $filterTarget $dnProtocol $dnIp $dnPort
 
        [ $dItem"x" == $dnItem"x" ] && continue
        dIp=`echo $dItem | awk -F":" '{print $1}'`
        dPort=`echo $dItem | awk -F":" '{print $2}'`
        dProtocol=`echo $dItem | awk -F":" '{print $3}'`
        [ "$dProtocol""x" == "x"  ] && dProtocol=$dnProtocol
        add_dnat $dProtocol $dIp $dPort $dnIp $dnPort
    done  
}


CONF_FILE=$1
[ "$CONF_FILE""x" == "x" ] && CONF_FILE="$workspace/iptables.ini"

#定期刷新功能，防止配置错误之后无法还原 
#while true
#do
    bootstrap  
    deal_conf     
#   sleep 600
#done 
