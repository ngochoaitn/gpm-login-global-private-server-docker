#!/bin/bash

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

# Tạo thư mục backup
BACKUP_DIR=$(pwd)
STORAGE_BACKUP_DIR="${BACKUP_DIR}/storage_backup"
# if [ ! -d "$BACKUP_DIR" ]; then mkdir "$BACKUP_DIR"; fi
if [ ! -d "$STORAGE_BACKUP_DIR" ]; then mkdir "$STORAGE_BACKUP_DIR"; fi

# Tạo tên file backup với ngày giờ
DATE=$(date +"%Y-%m-%d_%H-%M")
FILE_DATE="$DATE"

# Export database
echo "Exporting MySQL database..."
docker exec "$MYSQL_CONTAINER" mysqldump -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" > "${BACKUP_DIR}/db_backup.sql"

# Backup thư mục storage
echo "Backing up storage folder..."
docker cp "$WEB_CONTAINER:/var/www/html/storage" "$STORAGE_BACKUP_DIR"

sudo apt install zip -y
ZIP_FILE="${BACKUP_DIR}/gpm_prv_sv_backup.zip"
zip -r "$ZIP_FILE" db_backup.sql storage_backup

sudo rm "${BACKUP_DIR}/db_backup.sql"
sudo rm -rf "${STORAGE_BACKUP_DIR}"

echo "Backup completed!"
echo "File backup: ${ZIP_FILE}"
