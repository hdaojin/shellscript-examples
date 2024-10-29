#!/bin/bash

# 设置数据库的相关信息
DB_USER="your_db_user" # 数据库用户名
DB_PASSWORD="your_db_password" # 数据库密码
DB_NAME="your_db_name" # 需要导入的数据库名
BACKUP_FILE="$1" # 备份文件的路径, 通过命令行参数传入

# 使用mariadb(mysql)命令导入备份
mariadb -u $DB_USER -p$DB_PASSWORD $DB_NAME < $BACKUP_FILE

# 检查mariadb命令是否成功执行
if [ $? -eq 0 ]; then
  echo "Database successfully imported from $BACKUP_FILE"
else
  echo "An error occurred during the import process"
fi