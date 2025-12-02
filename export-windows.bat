@echo off
setlocal EnableDelayedExpansion

REM Đọc biến từ file .env
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_DATABASE=" .env') do set DB_DATABASE=%%b
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_USERNAME=" .env') do set DB_USERNAME=%%b
for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PASSWORD=" .env') do set DB_PASSWORD=%%b

REM Lấy tên container MySQL và Web
:: for %%I in (.) do set CURRENT_DIR=%%~nI
set MYSQL_CONTAINER="gpm_login_global_private_server_mysql"
set WEB_CONTAINER="gpm_login_global_private_server_web"

REM Tạo thư mục backup
set BACKUP_DIR=%~dp0
set STORAGE_BACKUP_DIR=%~dp0storage_backup
:: if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%STORAGE_BACKUP_DIR%" mkdir "%STORAGE_BACKUP_DIR%"

REM Tạo tên file backup với ngày giờ
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    set YYYY=%%l
    set MM=%%j
    set DD=%%k
)
for /f "tokens=1-2 delims=: " %%i in ("%time%") do (
    set HH=%%i
    set MIN=%%j
)
:: set FILE_DATE=%YYYY%-%MM%-%DD%_%HH%-%MIN%

REM Export database
echo Exporting MySQL database...
docker exec %MYSQL_CONTAINER% mysqldump -u%DB_USERNAME% -p%DB_PASSWORD% %DB_DATABASE% > "%BACKUP_DIR%db_backup.sql"

REM Backup thư mục storage
echo Backing up storage folder...
docker cp %WEB_CONTAINER%:/var/www/html/storage "%STORAGE_BACKUP_DIR%"

echo Backup completed!
echo Database: %BACKUP_DIR%db_backup.sql
echo Storage: %STORAGE_BACKUP_DIR%
pause
endlocal
