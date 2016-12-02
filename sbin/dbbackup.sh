#!/bin/bash

DB_KEY_INDEX=1
DB_IP_INDEX=2
DB_PORT_INDEX=3
DB_USER_INDEX=4
DB_PWD_INDEX=5
DB_NAME_INDEX=6

MYSQL_FORLDER=$HOME/local/mysql/bin
MYSQL_BIN=$MYSQL_FORLDER/mysql
MYSQLDUMP_BIN=$MYSQL_FORLDER/mysqldump
DUMP_PLACE=$HOME/backup/mysql/`date '+%Y%m%d%H%M%S'`
DBDATA_FILENAME="db.txt"

function backupMysql (){
    database_ip=$1
	database_port=$2
	database_username=$3
	database_passwd=$4
	database_dbname=$5
	dest_file_name=$6

	mkdir $DUMP_PLACE -p
	echo "Execute command: $MYSQLDUMP_BIN -h $database_ip -P $database_port -u $database_username -p $database_passwd $database_dbname > $DUMP_PLACE/$database_dbname.sql"
	$MYSQLDUMP_BIN -h$database_ip -P$database_port -u$database_username -p$database_passwd $database_dbname > $DUMP_PLACE/$database_dbname.sql
	cp $DUMP_PLACE/$database_dbname.sql $DUMP_PLACE/$dest_file_name.sql
}

function restoreMysql() {
    database_ip=$1
	database_port=$2
	database_username=$3
	database_passwd=$4
	database_dbname=$5
	src_file_name=$6

	cp $DUMP_PLACE/$src_file_name.sql $DUMP_PLACE/$database_dbname.sql
    echo "Execute command: $MYSQL_BIN -h$database_ip -P$database_port -u$database_username -p$database_passwd -D $database_dbname < $DUMP_PLACE/$database_dbname.sql"
    $MYSQL_BIN -h$database_ip -P$database_port -u$database_username -p$database_passwd -D $database_dbname < $DUMP_PLACE/$database_dbname.sql
}

function getLineFromKey() {
	
    lineCount=`grep $1 $DBDATA_FILENAME | wc -l` 
	line=$(grep $1 $DBDATA_FILENAME)
    if [ $lineCount -ne 1 ]; then
        echo "find no data or one more data. error:"
        grep $1 $DBDATA_FILENAME
		echo "check in $DBDATA_FILENAME"
        exit 0
    fi

	#ip, port, user, password, dbname
	params=`echo $line | awk -F"," '{print $3" "$4" "$5" "$6" "$7}'`
	echo $params
} 

function print_help() { 
    echo "params count must be 1 or 2. They are:"
    echo "[src_key, dest_key. dest_key is optional.]"
}

function Main() {

	fileName="temp.sql"

	if [ $# -eq 0 ]; then
		print_help
		exit 0
	fi
	
	src=`getLineFromKey $1`
	backupMysql $src $fileName
	
	if [ $2"x" != "x" ]; then
		dest=`getLineFromKey $2`
		restoreMysql $dest $fileName
	fi	
}

Main $@
