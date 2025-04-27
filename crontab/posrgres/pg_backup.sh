#!/bin/bash

# PostgreSQL 备份脚本
# 配置参数
DB_HOST=${PGSQL_HOST}
DB_PORT=${PGSQL_PORT}
DB_USER=${PGSQL_USER}
DB_PASSWORD=${PGSQL_PASSWORD}
DOCKER_IMAGE="postgres:latest"

# 备份目录设置
BACKUP_DIR="/data/backups/posrgres/$(date +%Y)/$(date +%Y%m)"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 获取用户可以访问的所有数据库列表
echo "获取可访问数据库列表..."
DB_LIST=$(docker run --rm \
    -e PGPASSWORD="${DB_PASSWORD}" \
    "${DOCKER_IMAGE}" \
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres') AND datistemplate = false;")

# 检查数据库列表
if [ -z "$DB_LIST" ]; then
    echo "没有找到可备份的数据库"
    exit 1
fi

# 备份每个数据库
for DB_NAME in $DB_LIST; do
    echo "开始备份数据库 ${DB_NAME}..."
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"
    
    docker run --rm \
        -e PGPASSWORD="${DB_PASSWORD}" \
        -v "${BACKUP_DIR}:/backups" \
        "${DOCKER_IMAGE}" \
        pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
        --no-password \
        --clean \
        --if-exists \
        -f "/backups/${DB_NAME}_${DATE}.sql"

    if [ $? -eq 0 ]; then
        echo "备份成功: ${BACKUP_FILE}"
    else
        echo "备份失败: ${DB_NAME}"
    fi
done

# 保留本月的最近7天备份
find "$BACKUP_DIR" -name "*_*.sql" -mtime +7 -type f -exec rm -f {} \;
# 删除非本年&本月的备份目录(仅在每月2号执行)
if [ $(date +%d) -eq 2 ]; then
    CURRENT_YEAR=$(date +%Y)
    CURRENT_MONTH=$(date +%m)
    find "/data/backups/posrgres/" -maxdepth 1 -type d -name "20*" | while read -r year_dir; do
        year=$(basename "$year_dir")
        if [ "$year" != "$CURRENT_YEAR" ]; then
            echo "删除非本年目录: $year_dir"
            rm -rf "$year_dir"
        else
            find "$year_dir" -maxdepth 1 -type d -name "20*" | while read -r month_dir; do
                month=$(basename "$month_dir" | cut -c5-6)
                if [ "$month" != "$CURRENT_MONTH" ]; then
                    echo "删除非本月目录: $month_dir"
                    rm -rf "$month_dir"
                fi
            done
        fi
    done
fi