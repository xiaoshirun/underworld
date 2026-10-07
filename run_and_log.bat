@echo off
echo Installing and running game with enhanced logging...
echo.

set HDC=D:\Software\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe
set HAP_PATH=entry\build\default\outputs\default\entry-default-unsigned.hap
set BUNDLE=com.xsr.underworld
set ABILITY=EntryAbility

echo Step 1: Checking device connection...
"%HDC%" list targets
if errorlevel 1 (
    echo ERROR: No device connected. Please start emulator first.
    pause
    exit /b 1
)

echo.
echo Step 2: Installing HAP...
"%HDC%" install "%HAP_PATH%"
if errorlevel 1 (
    echo ERROR: Installation failed
    pause
    exit /b 1
)

echo.
echo Step 3: Clearing old logs...
"%HDC%" shell hilog -r

echo.
echo Step 4: Starting application...
"%HDC%" shell aa start -a %ABILITY% -b %BUNDLE%

echo.
echo Step 5: Capturing logs (press Ctrl+C to stop)...
echo Saving to game_logs.txt...
"%HDC%" shell hilog -x > game_logs.txt

echo.
echo Logs saved to game_logs.txt
echo Please share this file for debugging.
pause
