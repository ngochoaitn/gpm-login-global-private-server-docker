#!/bin/bash

echo "!!!!!! All current data will remove for restore data"
read -p "Press any key to continue..."

# Kiểm tra nếu file backup không tồn tại
if [ ! -f "gpm_prv_sv_backup.zip" ]; then
    echo "Backup file gpm_prv_sv_backup.zip not found!"
    read -p "Press any key to exit..."
    exit 1
fi

sudo apt install unzip -y
sudo unzip gpm_prv_sv_backup.zip -d .

# Đọc biến từ file .env
export DB_DATABASE=$(grep -oP '^DB_DATABASE=\K.*' .env)
export DB_USERNAME=$(grep -oP '^DB_USERNAME=\K.*' .env)
export DB_PASSWORD=$(grep -oP '^DB_PASSWORD=\K.*' .env)

# Lấy tên container MySQL và Web
CURRENT_DIR=$(basename "$PWD")
MYSQL_CONTAINER="gpm_login_global_private_server_mysql"
WEB_CONTAINER="gpm_login_global_private_server_web"

# Kiểm tra nếu container MySQL tồn tại
MYSQL_EXIST=$(sudo docker ps -a --filter "name=$MYSQL_CONTAINER" --format "{{.Names}}")
if [ "$MYSQL_EXIST" == "$MYSQL_CONTAINER" ]; then
    echo "Container $MYSQL_CONTAINER exists."
else
    # Kiểm tra tên container với dấu _ thay vì -
    MYSQL_CONTAINER="${CURRENT_DIR}_mysql_1"
    MYSQL_EXIST=$(sudo docker ps -a --filter "name=$MYSQL_CONTAINER" --format "{{.Names}}")
    if [ "$MYSQL_EXIST" == "$MYSQL_CONTAINER" ]; then
        echo "Container $MYSQL_CONTAINER exists."
    else
        echo "Container $MYSQL_CONTAINER does not exist."
    fi
fi

# Kiểm tra sự tồn tại của Web container (tương tự)
WEB_EXIST=$(sudo docker ps -a --filter "name=$WEB_CONTAINER" --format "{{.Names}}")
if [ "$WEB_EXIST" == "$WEB_CONTAINER" ]; then
    echo "Container $WEB_CONTAINER exists."
else
    # Kiểm tra tên container với dấu _ thay vì -
    WEB_CONTAINER="${CURRENT_DIR}_web_1"
    WEB_EXIST=$(sudo docker ps -a --filter "name=$WEB_CONTAINER" --format "{{.Names}}")
    if [ "$WEB_EXIST" == "$WEB_CONTAINER" ]; then
        echo "Container $WEB_CONTAINER exists."
    else
        echo "Container $WEB_CONTAINER does not exist."
    fi
fi

# Đường dẫn file backup và storage
BACKUP_DIR=$(pwd)
STORAGE_BACKUP_DIR="${BACKUP_DIR}/storage_backup"

# Kiểm tra file SQL tồn tại
if [ ! -f "${BACKUP_DIR}/db_backup.sql" ]; then
    echo "File database backup not found: ${BACKUP_DIR}/db_backup.sql"
    read -p "Press any key to exit..."
    exit 1
fi

# Drop và tạo lại database
echo "Dropping and recreating database ${DB_DATABASE}..."
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS \`${DB_DATABASE}\`; CREATE DATABASE \`${DB_DATABASE}\`;"

# Import database
echo "Restoring MySQL database..."
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < "${BACKUP_DIR}/db_backup.sql"

# Kiểm tra thư mục storage backup tồn tại
if [ ! -d "${STORAGE_BACKUP_DIR}/storage" ]; then
    echo "Storage backup folder not found: ${STORAGE_BACKUP_DIR}/storage"
    read -p "Press any key to exit..."
    exit 1
fi

# Restore thư mục storage
echo "Restoring storage folder..."
docker cp "${STORAGE_BACKUP_DIR}/storage" "$WEB_CONTAINER":/var/www/html/

# Chown lại storage cho www-data
echo "Changing owner of storage folder..."
docker exec "$WEB_CONTAINER" chown -R www-data:www-data /var/www/html/storage

echo "Restore completed!"
read -p "Press any key to exit..."
