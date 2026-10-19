@echo off
setlocal
set "WIFI_NAME=Wi-Fi"

:menu
cls
echo ===== Wi-Fi Ping Tool =====
echo 1. Monitor Google and restart Wi-Fi if ping fails
echo 2. Ping Google a chosen number of times
echo 3. Exit
echo.
set "CHOICE="
set /p "CHOICE=Choose an option: "

if "%CHOICE%"=="1" goto monitor
if "%CHOICE%"=="2" goto multiple
if "%CHOICE%"=="3" exit /b
goto menu

:monitor
cls
echo Monitoring Google with 3 pings every 30 seconds.
echo Press Ctrl+C to stop.
echo.

:monitorloop
ping -n 3 -w 2000 google.com
if errorlevel 1 (
    echo.
    echo Ping failed. Restarting %WIFI_NAME%...
    netsh interface set interface name="%WIFI_NAME%" admin=disabled
    timeout /t 5 /nobreak >nul
    netsh interface set interface name="%WIFI_NAME%" admin=enabled
    timeout /t 15 /nobreak >nul
) else (
    echo Ping succeeded.
)

echo Checking again in 30 seconds...
timeout /t 30 /nobreak >nul
goto monitorloop

:multiple
cls
set "COUNT="
set /p "COUNT=How many times should it ping Google? Enter a positive whole number: "
if not defined COUNT goto menu

echo.
ping -n %COUNT% google.com
echo.
pause
goto menu
