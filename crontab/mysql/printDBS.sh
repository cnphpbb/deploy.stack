#!/usr/bin/env bash

# MySQL 用户名、密码、主机和端口
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT="3306"

# 不需要备份的数据库列表
EXCLUDE_DATABASES=("information_schema" "performance_schema" "mysql" "sys")

# 创建临时配置文件
MYSQL_CONFIG=${HOME}/mysql.cnf
cat > $MYSQL_CONFIG <<EOF
[client]
user=${MYSQL_USER}
password=${MYSQL_PASSWORD}
host=${MYSQL_HOST}
port=${MYSQL_PORT}
EOF

# 获取所有数据库并过滤
DATABASES=$(mysql --defaults-extra-file=$MYSQL_CONFIG --silent -e "SHOW DATABASES;" | grep -Ev "^Database$|^($(IFS="|"; echo "${EXCLUDE_DATABASES[*]}"))$")

# 打印数据库列表
echoDBS() {
    echo "需要备份的数据库: "
    # 使用for循环打印过滤后的数据库
    for db in ${DATABASES}; do
        echo "${db}"
    done
    # 删除临时文件
    rm -f $MYSQL_CONFIG
}

# 打印数据库及其大小
echoDBSSize() {
    echo "需要备份的数据库及其大小: "
    local TOTAL_SIZE=0
    # 使用for循环打印过滤后的数据库及其大小
    for db in ${DATABASES}; do
        SIZE=$(mysql --defaults-extra-file=$MYSQL_CONFIG --silent -e "SELECT IFNULL(ROUND(SUM(data_length + index_length) / 1024 / 1024, 2), 0) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = '${db}';" | grep -v "Size (MB)")
        echo "${db} - ${SIZE} MB"
        TOTAL_SIZE=$(echo "$TOTAL_SIZE + $SIZE" | bc)
    done
    echo "-------------------------"
    TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)
    echo "总大小: ${TOTAL_SIZE} MB (${TOTAL_SIZE_GB} GB)"
    # 删除临时文件
    rm -f $MYSQL_CONFIG
}

help() {
    echo "使用方法:"
    echo "  $(basename "$0") [选项]"
    echo ""
    echo "选项:"
    echo "  -l, --list      列出需要备份的数据库"
    echo "  -s, --size      列出需要备份的数据库及其大小"
    echo "  -h, --help      显示帮助信息"
}

# 处理输入参数
case "$1" in
    -l|--list)
        echoDBS
        ;;
    -s|--size)
        echoDBSSize
        ;;
    -h|--help)
        help
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        help
        exit 1
        ;;
esac

