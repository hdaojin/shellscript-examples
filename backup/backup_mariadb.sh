#!/bin/bash

# 设置数据库的相关信息
DB_USER="your_db_user" # 数据库用户名
DB_PASSWORD="your_db_password" # 数据库密码
DB_NAME="your_db_name" # 需要备份的数据库名
BACKUP_DIR="/path/to/your/backup/directory" # 备份文件存放的目录
DATE=$(date +%Y%m%d%H%M) # 获取当前时间作为文件名的一部分

# 创建备份文件的文件名
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$DATE.sql"

# 使用mysqldump创建备份
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE

# 检查mysqldump命令是否成功执行
if [ $? -eq 0 ]; then
  echo "Database backup successfully saved to $BACKUP_FILE"
else
  echo "An error occurred during the backup process"
fi
