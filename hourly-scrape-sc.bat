@echo off
setlocal enabledelayedexpansion

REM ================================================
REM hourly-scrape-sc.bat
REM
REM Runs SC scan, captures wait alerts, pushes to GitHub.
REM Mirrors hourly-scrape-ga.bat — only paths and script names differ.
REM ================================================

REM --- EDIT THESE PATHS IF DIFFERENT ---
SET SCRAPER_DIR=C:\access-intel-sc
SET GITHUB_REPO=C:\access-intel-sc-web

SET LOG_DIR=%SCRAPER_DIR%\logs
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
SET LOG_FILE=%LOG_DIR%\scrape-%date:~10,4%-%date:~4,2%-%date:~7,2%.log

echo. >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo Run started: %date% %time% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"

cd /d "%SCRAPER_DIR%"

echo [Scraper] Running Prisma scan... >> "%LOG_FILE%"
call python sc-scraper.py >> "%LOG_FILE%" 2>&1

echo [WaitAlerts] Checking wait times... >> "%LOG_FILE%"
call python sc-save_wait_time_alerts.py >> "%LOG_FILE%" 2>&1

REM ================================================
REM PUSH TO GITHUB
REM ================================================
if not exist "%SCRAPER_DIR%\data\current.json" (
    echo ERROR: current.json not found >> "%LOG_FILE%"
    goto :end
)
if not exist "%GITHUB_REPO%" (
    echo ERROR: GitHub repo not found at %GITHUB_REPO% >> "%LOG_FILE%"
    goto :end
)

cd /d "%GITHUB_REPO%"
call git pull origin main --no-rebase --strategy-option=ours --no-edit >> "%LOG_FILE%" 2>&1
copy /Y "%SCRAPER_DIR%\data\current.json" "%GITHUB_REPO%\current.json" >> "%LOG_FILE%" 2>&1
if exist "%SCRAPER_DIR%\data\wait_alerts.json" (
    copy /Y "%SCRAPER_DIR%\data\wait_alerts.json" "%GITHUB_REPO%\wait_alerts.json" >> "%LOG_FILE%" 2>&1
)

call git add current.json wait_alerts.json >> "%LOG_FILE%" 2>&1
call git commit -m "Hourly SC update %date% %time%" >> "%LOG_FILE%" 2>&1
call git push origin main >> "%LOG_FILE%" 2>&1

:end
echo Run completed: %date% %time% >> "%LOG_FILE%"
endlocal
