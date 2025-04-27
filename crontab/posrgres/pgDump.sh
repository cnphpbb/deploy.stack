#!/usr/bin/env bash
# @author: cnphpbb@hotmail.com
# @date: 2025-04-27
# @desc: PostgreSQL数据库备份脚本

## 基础配置
TOYEAR=$(date "+%Y")
TOMONTH=$(date "+%Y%m")
TODATE=$(date "+%Y%m%d")
NOWDATE=$(date "+%Y%m%d-%H%M%S")
BACKDIR=/data/backups/pg_backs # 备份目录
TARLOGDIR=/data/backups/pg_tar_logs # 日志目录
DAYDIR=${BACKDIR}/${TOMONTH}/${TODATE}
BACKLOGSDIR=${TARLOGDIR}/${TOMONTH}/logs/${TODATE}
BACKTARDIR=${TARLOGDIR}/${TOMONTH}/db_tars
LOGFILE=${BACKLOGSDIR}/pg-Dump.${NOWDATE}.log
BACKSQLFILE=""
FileSize=0

## PostgreSQL配置
USERNAME=${PGSQL_USER}
PASSWORD=${PGSQL_PASS}
HOST=${PGSQL_HOST}
PORT=${PGSQL_PORT}
DOCKER_IMAGE="postgres:latest"

## 创建目录
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

## 工具函数
curTime() {
  NOWDATE=$(date "+%Y%m%d-%H%M%S")
}

getLogFile(){
  curTime
  LOGFILE=${BACKLOGSDIR}/pg-Dump.${NOWDATE}.log
}

# 备份整个数据库
db_full_backup() {
  curTime
  BACKSQLFILE=${DAYDIR}/$1-${NOWDATE}.sql
  docker run --rm \
    -e PGPASSWORD="${PASSWORD}" \
    -v "${DAYDIR}:/backups" \
    "${DOCKER_IMAGE}" \
    pg_dump -h "${HOST}" -p "${PORT}" -U "${USERNAME}" -d "$1" \
    --no-password \
    --clean \
    --if-exists \
    -f "/backups/$1-${NOWDATE}.sql"
  
  gzip ${BACKSQLFILE}
  getLogFile
  if [ $? -ne 0 ]; then
      echo "$NOWDATE PostgreSQL数据库 $1 备份失败!" >> ${LOGFILE}
  else
      echo "$NOWDATE PostgreSQL数据库 $1 备份成功!" >> ${LOGFILE}
  fi
}

# 备份单个表
sigle_table_backup(){
  curTime
  BACKSQLFILE=${DAYDIR}/$1_$2-${NOWDATE}.sql
  docker run --rm \
    -e PGPASSWORD="${PASSWORD}" \
    -v "${DAYDIR}:/backups" \
    "${DOCKER_IMAGE}" \
    pg_dump -h "${HOST}" -p "${PORT}" -U "${USERNAME}" -d "$1" \
    --no-password \
    --clean \
    --if-exists \
    -t "$2" \
    -f "/backups/$1_$2-${NOWDATE}.sql"
    
  gzip ${BACKSQLFILE}
  getLogFile
  if [ $? -ne 0 ]; then
    echo "$NOWDATE PostgreSQL表 $1.$2 备份失败!" >> ${LOGFILE}
  else
    echo "$NOWDATE PostgreSQL表 $1.$2 备份成功!" >> ${LOGFILE}
  fi
}

selfHelp() {
  echo "pgDump.sh 帮助文档"
  echo "-----------------------------------"
  echo "-h --help 显示帮助信息"
  echo
  echo "\$1 数据库名 (备份整个数据库)"
  echo "示例: pgDump.sh memos_db"
  echo
  echo "\$2 表名 (备份单个表)"
  echo "示例: pgDump.sh memos_db users"
}

## 主逻辑
case $1 in
  -h|--help|help )
    selfHelp
  ;;
  *)
    if [ $# -eq 1 ]; then
      echo "开始备份PostgreSQL数据库 $1..."
      db_full_backup $1
      FileSize=$(stat -c %s ${BACKSQLFILE})
      echo "备份文件: ${BACKSQLFILE}  ${FileSize} bytes"
      echo "完成备份PostgreSQL数据库 $1"
    else
      echo "开始备份PostgreSQL表 $1.$2..."
      sigle_table_backup $1 $2
      FileSize=$(stat -c %s ${BACKSQLFILE})
      echo "备份文件: ${BACKSQLFILE}  ${FileSize} bytes"
      echo "完成备份PostgreSQL表 $1.$2"
    fi
  ;;
esac