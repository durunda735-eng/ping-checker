@echo off
setlocal

:: =====================================================================
:: ADMIN RIGHTS CHECK
:: This section checks if the script was run as an Administrator.
:: 'net session' is a command that only works if you have admin rights.
:: If the errorlevel is not 0 (meaning the command failed), it prints
:: a warning message, pauses so you can read it, and then exits.
:: =====================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ===================================================
    echo ERROR: Administrator Privileges Required!
    echo ===================================================
    echo This script needs to reset hardware, which requires
    echo admin rights. Please right-click this file and
    echo select "Run as administrator".
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b
)

:: =====================================================================
:: ADAPTER DETECTION
:: This section finds the actual name of the active internet connection.
:: It uses PowerShell to check all network adapters, filters for the one 
:: that has a Default Gateway (meaning it connects to the internet), 
:: and saves its name into the 'ACTIVE_ADAPTER' variable.
:: =====================================================================
echo Detecting your active network adapter...

set "ACTIVE_ADAPTER="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-NetAdapter | Where-Object { (Get-NetIPConfiguration -InterfaceAlias $_.Name).IPv4DefaultGateway } | Select-Object -First 1).Name"') do set "ACTIVE_ADAPTER=%%A"

:: =====================================================================
:: OFFLINE FAILSAFE
:: If the script couldn't find an active adapter (because internet 
:: is completely disconnected before starting), it alerts and stops.
:: =====================================================================
if "%ACTIVE_ADAPTER%"=="" (
    echo.
    echo ERROR: Could not detect an active internet connection.
    echo Please connect to Wi-Fi or Ethernet first so the script knows what to monitor.
    echo.
    pause
    exit /b
)

:: =====================================================================
:: MAIN MENU
:: Clears the screen (cls) and displays the user options.
:: =====================================================================
:menu
cls
echo ===== Connection Ping Tool =====
echo Monitoring Adapter: "%ACTIVE_ADAPTER%"
echo ================================
echo 1. Ping Google and restart adapter if ping fails
echo 2. Ping Google a chosen number of times
echo 3. Exit
echo.
set "CHOICE="
set /p "CHOICE=Choose an option: "

if "%CHOICE%"=="1" goto monitor
if "%CHOICE%"=="2" goto multiple
if "%CHOICE%"=="3" exit /b
goto menu

:: =====================================================================
:: MONITOR
:: Option 1. It just clears the screen and prints
:: the instructions before starting the actual loop.
:: =====================================================================
:monitor
cls
echo Monitoring Google with 3 pings every 30 seconds.
echo Target adapter: "%ACTIVE_ADAPTER%"
echo Press Ctrl+C to stop.
echo.

:: =====================================================================
:: THE LOOP
:: This section runs endlessly. It pings Google 3 times.
:: If the ping fails, it uses 'netsh' to disable and re-enable 
:: the specific adapter.
:: The 'timeout' commands create pauses so the hardware has time to reset
:: and reconnect before checking again.
:: =====================================================================
:monitorloop
ping -n 3 -w 2000 google.com
if errorlevel 1 (
    echo.
    echo Ping failed. Restarting "%ACTIVE_ADAPTER%"...
    netsh interface set interface name="%ACTIVE_ADAPTER%" admin=disabled
    timeout /t 5 /nobreak >nul
    netsh interface set interface name="%ACTIVE_ADAPTER%" admin=enabled
    timeout /t 15 /nobreak >nul
) else (
    echo Ping succeeded.
)

echo Checking again in 30 seconds...
timeout /t 30 /nobreak >nul
goto monitorloop

:: =====================================================================
:: MANUAL PING — This is Option 2.
:: It replaces %COUNT% with the set number and pings.
:: The 'pause' command stops the screen from instantly clearing so 
:: you can read the results before it goes back to the menu.
:: =====================================================================
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