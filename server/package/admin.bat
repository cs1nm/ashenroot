@echo off
setlocal
set ROOT=%~dp0
if not exist "%ROOT%data" mkdir "%ROOT%data"
if "%~1"=="" (
  echo Usage: admin.bat STATUS^|SAVE^|KICK peer_id^|BAN peer_id^|CLEAR_BANS^|SHUTDOWN [reason]
  exit /b 2
)
> "%ROOT%data\admin_commands.txt" echo %*
echo Queued admin command: %*
endlocal
