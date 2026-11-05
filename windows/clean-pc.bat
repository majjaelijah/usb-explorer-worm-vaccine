@echo off
rem Removes the GPLControl.exe background copy of the USB-Explorer worm from this PC.
rem Run it while signed in as EVERY user who plugged in an infected drive
rem (the startup entry is per user).
setlocal
set "WORM=C:\Users\Public\Libraries\GPLControl.exe"
set "RUNKEY=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

taskkill /F /IM GPLControl.exe >nul 2>&1
reg delete "%RUNKEY%" /v GPLControl /f >nul 2>&1
if exist "%WORM%" (
  attrib -R -S -H "%WORM%"
  del /F /Q "%WORM%"
)

echo.
set "OK=1"
if exist "%WORM%" (
  set "OK="
  echo WARNING: %WORM% still exists. Restart the PC and run this again.
)
reg query "%RUNKEY%" /v GPLControl >nul 2>&1
if not errorlevel 1 (
  set "OK="
  echo WARNING: startup entry GPLControl still exists.
)
if defined OK echo This PC is clean of GPLControl for the current user.
echo Now run a Full scan in Windows Security (Microsoft Defender).
exit /b 0
