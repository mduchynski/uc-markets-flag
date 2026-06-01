@echo off
setlocal enabledelayedexpansion

REM ================================================
REM hourly-scrape-oh.bat
REM
REM Runs OH scan, captures wait alerts, pushes to GitHub.
REM Mirrors hourly-scrape-ga.bat — only paths and script names differ.
REM ================================================

SET SCRAPER_DIR=C:\access-intel-oh
SET GITHUB_REPO=C:\access-intel-oh-web

SET LOG_DIR=%SCRAPER_DIR%\logs
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
SET LOG_FILE=%LOG_DIR%\scrape-%date:~10,4%-%date:~4,2%-%date:~7,2%.log

echo. >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo Run started: %date% %time% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"

cd /d "%SCRAPER_DIR%"

echo [Scraper] Running UH scan... >> "%LOG_FILE%"
call python oh-scraper.py >> "%LOG_FILE%" 2>&1

echo [WaitAlerts] Checking wait times... >> "%LOG_FILE%"
call python oh-save_wait_time_alerts.py >> "%LOG_FILE%" 2>&1

if not exist "%SCRAPER_DIR%\data\current.json" goto :end
if not exist "%GITHUB_REPO%" goto :end

cd /d "%GITHUB_REPO%"
call git pull origin main --no-rebase --strategy-option=ours --no-edit >> "%LOG_FILE%" 2>&1
copy /Y "%SCRAPER_DIR%\data\current.json" "%GITHUB_REPO%\current.json" >> "%LOG_FILE%" 2>&1
if exist "%SCRAPER_DIR%\data\wait_alerts.json" (
    copy /Y "%SCRAPER_DIR%\data\wait_alerts.json" "%GITHUB_REPO%\wait_alerts.json" >> "%LOG_FILE%" 2>&1
)
call git add current.json wait_alerts.json >> "%LOG_FILE%" 2>&1
call git commit -m "Hourly OH update %date% %time%" >> "%LOG_FILE%" 2>&1
call git push origin main >> "%LOG_FILE%" 2>&1

:end
echo Run completed: %date% %time% >> "%LOG_FILE%"
endlocal
