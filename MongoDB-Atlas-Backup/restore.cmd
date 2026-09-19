@echo off
setlocal enabledelayedexpansion

:: Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set CONFIG_FILE=%SCRIPT_DIR%config.cmd

echo ===================================================
echo MongoDB Automated Restore Script
echo ===================================================

:: 1. CHECK FOR CONFIGURATION FILE
if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
) else (
    echo [ERROR] Configuration file not found!
    echo Please copy 'config.example.cmd' to 'config.cmd' and add your details.
    pause
    exit /b 1
)

:: 2. PREREQUISITE CHECK: IS MONGORESTORE INSTALLED?
where mongorestore >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'mongorestore' is not recognized.
    echo Please install MongoDB Database Tools and ensure it is added to your system PATH.
    pause
    exit /b 1
)

:: 3. PROMPT FOR TARGET CONNECTION STRING (Safety Measure)
echo.
echo [SAFETY PROTOCOL] To prevent accidental overwrites, the database URI 
echo from config.cmd is ignored during restores.
:PROMPT_URI
echo.
set /p TARGET_URI="Enter the TARGET MongoDB Connection String (URI): "
:: Strip any accidental quotes the user might have pasted
set "TARGET_URI=!TARGET_URI:"=!"
if "!TARGET_URI!"=="" (
    echo URI cannot be empty. Please try again.
    goto PROMPT_URI
)

:: 4. SELECT BACKUP DATE
echo.
echo ===================================================
echo STEP 1: Select Backup Date
echo ===================================================
if not exist "!BACKUP_DIR!" (
    echo [ERROR] Backup directory !BACKUP_DIR! does not exist.
    pause
    exit /b 1
)

set date_count=0
for /d %%D in ("!BACKUP_DIR!\*") do (
    set /a date_count+=1
    set "DATE_!date_count!=%%~nxD"
    echo [!date_count!] %%~nxD
)

if !date_count!==0 (
    echo No backups found in !BACKUP_DIR!
    pause
    exit /b 1
)

:SELECT_DATE
echo.
set /p DATE_SEL="Enter the number of the date you want to restore (1-!date_count!): "
call set "SELECTED_DATE=%%DATE_!DATE_SEL!%%"
if "!SELECTED_DATE!"=="" (
    echo Invalid selection. Please try again.
    goto SELECT_DATE
)
set "DATE_PATH=!BACKUP_DIR!\!SELECTED_DATE!"

:: 5. SELECT SPECIFIC DATABASE
echo.
echo ===================================================
echo STEP 2: Select Database to Restore
echo ===================================================
set db_count=0
for /d %%B in ("!DATE_PATH!\*") do (
    set /a db_count+=1
    set "DB_!db_count!=%%~nxB"
    echo [!db_count!] %%~nxB
)

:: Add an option to restore all databases if multiple exist
set /a all_db_opt=!db_count!+1
set "DB_!all_db_opt!=ALL DATABASES"
echo [!all_db_opt!] Restore ALL databases inside this date folder

:SELECT_DB
echo.
set /p DB_SEL="Enter the number of the database to restore (1-!all_db_opt!): "
call set "SELECTED_DB=%%DB_!DB_SEL!%%"
if "!SELECTED_DB!"=="" (
    echo Invalid selection. Please try again.
    goto SELECT_DB
)

if "!SELECTED_DB!"=="ALL DATABASES" (
    set "RESTORE_PATH=!DATE_PATH!"
) else (
    set "RESTORE_PATH=!DATE_PATH!\!SELECTED_DB!"
)

:: 6. DROP EXISTING DATA PROMPT
echo.
echo ===================================================
echo STEP 3: Overwrite Protocol
echo ===================================================
echo Do you want to DROP existing collections before restoring?
echo [Y] - Yes, delete existing data and replace it with this backup.
echo [N] - No, just merge the backup data into the existing database.
set DROP_FLAG=
:PROMPT_DROP
set /p DROP_PROMPT="Select Y or N: "
if /i "!DROP_PROMPT!"=="Y" (
    set "DROP_FLAG=--drop"
) else if /i "!DROP_PROMPT!"=="N" (
    set "DROP_FLAG="
) else (
    echo Invalid input.
    goto PROMPT_DROP
)

:: 7. FINAL CONFIRMATION
echo.
echo ===================================================
echo FINAL RESTORE SUMMARY
echo ===================================================
echo TARGET URI  : !TARGET_URI!
echo BACKUP DATE : !SELECTED_DATE!
echo TARGET DATA : !SELECTED_DB!
echo SOURCE FOLDER: !RESTORE_PATH!
if "!DROP_FLAG!"=="--drop" (
    echo OVERWRITE   : ENABLED [WARNING: Target database will be wiped first]
) else (
    echo OVERWRITE   : DISABLED [Data will be merged]
)
echo ===================================================
echo.
set /p CONFIRM="Type YES in all caps to execute this restore: "
if not "!CONFIRM!"=="YES" (
    echo.
    echo Restore cancelled by user. No changes were made.
    pause
    exit /b 0
)

:: 8. EXECUTE RESTORE
echo.
echo [%DATE% %TIME%] Starting mongorestore...
mongorestore --uri="!TARGET_URI!" --gzip !DROP_FLAG! "!RESTORE_PATH!"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [%DATE% %TIME%] [SUCCESS] Restore completed successfully!
) else (
    echo.
    echo [%DATE% %TIME%] [ERROR] Restore failed. Please check the output above.
)

pause
endlocal