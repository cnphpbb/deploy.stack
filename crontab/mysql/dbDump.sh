#!/usr/bin/env bash
# @author: cnphpbb@hotmail.com
# @date: 2024-08-28
# @desc: 备份数据库
## 备份数据库

## base
TOYEAR=$(date "+%Y")
TOMONTH=$(date "+%Y%m")
TODATE=$(date "+%Y%m%d")
NOWDATE=$(date "+%Y%m%d-%H%M%S")
BACKDIR=/data/backup/db_backs # 备份目录 请按照实际情况修改
TARLOGDIR=/data/backup/db_tar_logs # 备份日志目录 请按照实际情况修改
DAYDIR=${BACKDIR}/${TOMONTH}/${TODATE}
BACKLOGSDIR=${TARLOGDIR}/${TOMONTH}/logs/${TODATE}
BACKTARDIR=${TARLOGDIR}/${TOMONTH}/db_tars
LOGFILE=${BACKLOGSDIR}/db-Dump.${NOWDATE}.log
BACKSQLFILE=""
FileSize=0

## cmd
MYSQLDUMP='/usr/local/mysql/bin/mysqldump' # 请按照实际情况修改

## mysql
PARAS=' --set-gtid-purged=OFF --single-transaction --triggers --routines --events '
USERNAME=${MYSQL_USER}
PASSWORD=${MYSQL_PASS}
HOST=${MYSQL_HOST}

###
if [ ! -d "${BACKLOGSDIR}" ]; then
    mkdir -p ${BACKLOGSDIR}
fi

if [ ! -d "${BACKTARDIR}" ]; then
    mkdir -p ${BACKTARDIR}
fi

cd ${BACKDIR}
if [ ! -d "${DAYDIR}" ]; then
    mkdir -vp "$DAYDIR" >> ${LOGFILE}
fi

curTime() {
  NOWDATE=$(date "+%Y%m%d-%H%M%S")
}

getLogFile(){
  curTime
  LOGFILE=${BACKLOGSDIR}/db-Dump.${NOWDATE}.log
}

# dump databases
db_full_backup() {
  curTime
  BACKSQLFILE=${DAYDIR}/$1-${NOWDATE}.sql
  $MYSQLDUMP -u${USERNAME} -p${PASSWORD} -h${HOST} ${PARAS} --databases $1 > ${BACKSQLFILE}
  gzip ${BACKSQLFILE}
  getLogFile
  gzip ${BACKSQLFILE}
  if [ $? -ne 0 ]; then
      echo "$NOWDATE DB $1 backup  is failed , please check it out!" >> ${LOGFILE}
  else
      echo "$NOWDATE DB $1 backup  is success!" >> ${LOGFILE}
  fi
}

# dump databases.tables
sigle_table_backup(){
  curTime
  BACKSQLFILE=${DAYDIR}/$1_$2-${NOWDATE}.sql
  $MYSQLDUMP -u${USERNAME} -p${PASSWORD} -h${HOST} ${PARAS} --databases $1 --tables $2 > ${BACKSQLFILE}
  gzip ${BACKSQLFILE}
  getLogFile
  if [ $? -ne 0 ]; then
    echo "$NOWDATE Table  $1_$2 backup  is failed ,please check it out!" >> ${LOGFILE}
  else
    echo "$NOWDATE Table  $1_$2 backup  is success!" >> ${LOGFILE}
  fi
}

selfHelp() {
  echo "dbDump.sh HELP "
  echo "-----------------------------------"
  echo "-h --help echo dbDump.sh HELP note"
  echo
  echo "\$1 databases 只备份数据库"
  echo "exp:: dbDump.sh ppospro_member"
  echo
  echo "\$2 tables 只备份数据库.数据表"
  echo "exp:: dbDump.sh ppospro_member ppospro_member"
  echo
}


case $1 in
  -h|--help|help )
    selfHelp
  ;;
  *)
    #echo "参数个数为：$#"
    if [ $# -eq 1 ]; then
      echo "备份数据库 $1 Begin ..."
      db_full_backup $1
      FileSize=$(stat -c %s ${BACKSQLFILE})
      echo "备份文件:: ${BACKSQLFILE}  ${FileSize} bytes."
      echo "备份数据库 $1 End ..."
    else
      echo "备份数据库 $1 $2 Begin ..."
      sigle_table_backup $1 $2
      FileSize=$(stat -c %s ${BACKSQLFILE})
      echo "备份文件:: ${BACKSQLFILE}  ${FileSize} bytes."
      echo "备份数据库 $1 $2 End ..."
    fi
  ;;
esac