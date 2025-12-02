@echo off
echo !!!!!! All current data will remove for restore data
pause

setlocal EnableDelayedExpansion

REM Đọc biến từ file .env
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_DATABASE=" .env') do set DB_DATABASE=%%b
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_USERNAME=" .env') do set DB_USERNAME=%%b
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PASSWORD=" .env') do set DB_PASSWORD=%%b

REM Lấy tên container MySQL và Web
for %%I in (.) do set CURRENT_DIR=%%~nI
set MYSQL_CONTAINER="gpm_login_global_private_server_mysql"
set WEB_CONTAINER="gpm_login_global_private_server_web"

REM Đường dẫn file backup và storage
set BACKUP_DIR=%~dp0
set STORAGE_BACKUP_DIR=%~dp0storage_backup

REM Kiểm tra file SQL tồn tại
if not exist "%BACKUP_DIR%db_backup.sql" (
    echo File database backup not found: %BACKUP_DIR%db_backup.sql
    pause
    exit /b
)

REM Drop và tạo lại database
echo Dropping and recreating database %DB_DATABASE%...
docker exec -i %MYSQL_CONTAINER% mysql -u%DB_USERNAME% -p%DB_PASSWORD% -e "DROP DATABASE IF EXISTS \`%DB_DATABASE%\`; CREATE DATABASE \`%DB_DATABASE%\`;"

REM Import database
echo Restoring MySQL database...
docker exec -i %MYSQL_CONTAINER% mysql -u%DB_USERNAME% -p%DB_PASSWORD% %DB_DATABASE% < "%BACKUP_DIR%db_backup.sql"

REM Kiểm tra thư mục storage backup tồn tại
if not exist "%STORAGE_BACKUP_DIR%\storage" (
    echo Storage backup folder not found: %STORAGE_BACKUP_DIR%\storage
    pause
    exit /b
)

REM Restore thư mục storage
echo Restoring storage folder...
docker cp "%STORAGE_BACKUP_DIR%\storage" %WEB_CONTAINER%:/var/www/html/

REM Chown lại storage cho www-data
echo Changing owner of storage folder...
docker exec %WEB_CONTAINER% chown -R www-data:www-data /var/www/html/storage

echo Restore completed!
pause
endlocal
