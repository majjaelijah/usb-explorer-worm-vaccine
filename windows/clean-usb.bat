@echo off
rem Removes the USB-Explorer worm from a USB drive, restores the hidden files,
rem then protects the drive. Clean the PC first with clean-pc.bat.
rem Usage: clean-usb.bat E:
setlocal
if "%~1"=="" (set /p DRV=Drive letter of the USB drive, e.g. E: ) else (set "DRV=%~1")
set "DRV=%DRV:~0,1%:"
if /I "%DRV%"=="C:" (echo Refusing to modify C:. & exit /b 1)
pushd %DRV%\ 2>nul
if errorlevel 1 (echo Drive %DRV% not found. & exit /b 1)
popd

call :kind "%DRV%\USB-Explorer.exe" LURE
if "%LURE%"=="file" (
  attrib -R -S -H "%DRV%\USB-Explorer.exe"
  del /F /Q "%DRV%\USB-Explorer.exe"
)
call :kind "%DRV%\USB-Explorer.exe" LURE
if "%LURE%"=="file" (echo Could not delete %DRV%\USB-Explorer.exe & exit /b 1)

call :kind "%DRV%\Explorer\MAYUNDO" HIDE
if not "%HIDE%"=="dir" goto checkdone
attrib -R -S -H "%DRV%\Explorer"
for /f "delims=" %%I in ('dir /b /a "%DRV%\Explorer\MAYUNDO" 2^>nul') do call :restore "%%I"
rd "%DRV%\Explorer\MAYUNDO" 2>nul
rd "%DRV%\Explorer" 2>nul

:checkdone
call :kind "%DRV%\Explorer" EXPL
if "%EXPL%"=="dir" (
  echo %DRV%\Explorer is not empty - check the CONFLICT items above, then run this again.
  exit /b 1
)

call "%~dp0vaccinate-usb.bat" %DRV%
exit /b %errorlevel%

rem :restore NAME  -> moves one item from Explorer\MAYUNDO back to the drive root
:restore
call :kind "%DRV%\%~1" DEST
if not "%DEST%"=="none" (echo CONFLICT, left in Explorer\MAYUNDO: %~1 & exit /b 0)
move "%DRV%\Explorer\MAYUNDO\%~1" "%DRV%\" >nul
call :kind "%DRV%\%~1" DEST
if not "%DEST%"=="none" echo Restored: %~1
exit /b 0

rem :kind PATH VAR  -> sets VAR to none, file or dir
:kind
set "_a=%~a1"
if not defined _a (set "%2=none" & exit /b 0)
if /I "%_a:~0,1%"=="d" (set "%2=dir") else (set "%2=file")
exit /b 0
