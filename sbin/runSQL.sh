#!/bin/sh
#export LD_LIBRARY_PATH="/home/work/local/mysql/lib/mysql:$LD_LIBRARY_PATH"
#mysql=`dirname $0`"/bin/mysql"
mysql="mysql"
. ./mysql.ini

runsql(){
if [ -n "$1" ]; then
	sql=$1	 
else
	return
fi


if [ ${dbpassword}"a" == "a" ];then
	password=""
else
	password="-p${dbpassword}"

fi

#echo $mysql -h${dbhost} -P${dbport} -u${dbuser} ${password}  ${dbname}
#echo "$sql"
$mysql -h${dbhost} -P${dbport} -u${dbuser} ${password}  ${dbname} << EOFMYSQL

set names utf8;
$sql

EOFMYSQL

}

runfile(){

sql=''
cat $1 | while read line
do
	
	echo $line | grep "^\s*use .*;\s*$" -i  >/dev/null
	if [ $? == 0 ]; then
		use=$line
		sql="$use"
	else
		sql="${sql}""$line"
		echo $line | grep ";"  >/dev/null
		if [ $? == 1 ]; then
			continue
		fi
	fi
	runsql "$sql"
	sql="$use"
done

}


if [ -e "$1" ]; then
	runfile "$1"
else
	runsql "$1"

fi 

