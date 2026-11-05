@echo off
rem Protects a USB drive against the USB-Explorer / GPLControl worm.
rem Usage: vaccinate-usb.bat E:
setlocal
if "%~1"=="" (set /p DRV=Drive letter of the USB drive, e.g. E: ) else (set "DRV=%~1")
set "DRV=%DRV:~0,1%:"
if /I "%DRV%"=="C:" (echo Refusing to modify C:. & exit /b 1)
pushd %DRV%\ 2>nul
if errorlevel 1 (echo Drive %DRV% not found. & exit /b 1)
popd

call :kind "%DRV%\Explorer" EXPL
call :kind "%DRV%\USB-Explorer.exe" LURE
if "%EXPL%"=="dir" (
  echo An "Explorer" FOLDER exists on %DRV% - the drive looks infected.
  echo Run clean-usb.bat %DRV% first.
  exit /b 1
)
if "%LURE%"=="file" (
  echo A USB-Explorer.exe FILE exists on %DRV% - the drive is infected.
  echo Run clean-usb.bat %DRV% first.
  exit /b 1
)

if "%EXPL%"=="none" (
  > "%DRV%\Explorer" echo DO NOT DELETE. Protection against the USB-Explorer / GPLControl worm.
  attrib +R "%DRV%\Explorer"
)
if "%LURE%"=="none" (
  mkdir "%DRV%\USB-Explorer.exe"
  > "%DRV%\USB-Explorer.exe\README - protection.txt" echo DO NOT DELETE this folder. It blocks the USB-Explorer worm from copying itself onto this drive.
  attrib +R "%DRV%\USB-Explorer.exe\README - protection.txt"
  attrib +R "%DRV%\USB-Explorer.exe"
)
echo %DRV% is now protected against the USB-Explorer / GPLControl worm.
exit /b 0

rem :kind PATH VAR  -> sets VAR to none, file or dir
:kind
set "_a=%~a1"
if not defined _a (set "%2=none" & exit /b 0)
if /I "%_a:~0,1%"=="d" (set "%2=dir") else (set "%2=file")
exit /b 0
