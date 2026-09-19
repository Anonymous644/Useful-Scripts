@echo off
setlocal enabledelayedexpansion

:: Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set CONFIG_FILE=%SCRIPT_DIR%config.cmd

echo ===================================================
echo MongoDB Automated Backup Script
echo ===================================================

:: 1. CHECK FOR CONFIGURATION FILE
if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
) else (
    echo [ERROR] Configuration file not found!
    echo Please copy 'config.example.cmd' to 'config.cmd' and add your credentials.
    pause
    exit /b 1
)

:: 2. VALIDATE VARIABLES & DETECT PLACEHOLDERS
if "%MONGO_URI%"=="" (
    echo [ERROR] MONGO_URI is missing in config.cmd!
    pause
    exit /b 1
)

:: Prevent users from running the script with the default template credentials
echo "%MONGO_URI%" | findstr /c:"<username>" >nul
if %ERRORLEVEL% equ 0 (
    echo [ERROR] Default credentials detected in config.cmd!
    echo Please replace ^<username^>, ^<password^>, etc., with your actual Atlas details.
    pause
    exit /b 1
)

if "%BACKUP_DIR%"=="" set "BACKUP_DIR=C:\MongoDB_Backups"
if "%RETENTION_DAYS%"=="" set RETENTION_DAYS=7

:: 3. PREREQUISITE CHECK: IS MONGODUMP INSTALLED?
where mongodump >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'mongodump' is not recognized.
    echo Please install MongoDB Database Tools and ensure it is added to your system PATH.
    pause
    exit /b 1
)

:: 4. PREPARE BACKUP DIRECTORY
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%" || (
        echo [ERROR] Failed to create backup directory at %BACKUP_DIR%. Check permissions.
        pause
        exit /b 1
    )
)

:: Generate YYYY-MM-DD timestamp using PowerShell
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd'"') do set BACKUP_DATE=%%I
set TARGET_DIR=%BACKUP_DIR%\%BACKUP_DATE%

:: 5. JOB SUMMARY & AUTO-COUNTDOWN
echo.
echo ===================================================
echo BACKUP JOB SUMMARY
echo ===================================================
echo SOURCE DB : %MONGO_URI%
echo DESTINATION : %TARGET_DIR%
echo RETENTION   : Keeping last %RETENTION_DAYS% days
echo ===================================================
echo.
echo Starting automatically in 10 seconds... (Press CTRL+C to cancel)
timeout /t 10

:: 6. EXECUTE BACKUP
echo.
echo [%DATE% %TIME%] Starting mongodump...
mongodump --uri=%MONGO_URI% --out="%TARGET_DIR%" --gzip

if %ERRORLEVEL% equ 0 (
    echo [%DATE% %TIME%] [SUCCESS] Backup completed!
) else (
    echo [%DATE% %TIME%] [ERROR] Backup failed. Check your connection string and network.
    pause
    exit /b %ERRORLEVEL%
)

:: 7. CLEANUP OLD BACKUPS
echo [%DATE% %TIME%] Cleaning up backups older than %RETENTION_DAYS% days...
ForFiles /p "%BACKUP_DIR%" /m "20*" /d -%RETENTION_DAYS% /c "cmd /c if @isdir==TRUE rmdir /s /q @path" 2>nul

echo.
echo [%DATE% %TIME%] All tasks finished successfully!
timeout /t 5
endlocal