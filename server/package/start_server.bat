@echo off
setlocal
set ROOT=%~dp0
if not exist "%ROOT%data" mkdir "%ROOT%data"
if "%WORLD%"=="" set WORLD=0
if "%PORT%"=="" set PORT=24567
if "%SERVER_NAME%"=="" set SERVER_NAME=My Shadowgrove
if "%PVP%"=="" set PVP=false
"%ROOT%AshenRootsServer.exe" --headless -- --dedicated --world=%WORLD% --port=%PORT% "--name=%SERVER_NAME%" "--password=%PASSWORD%" --pvp=%PVP% "--admin=%ROOT%data\admin_commands.txt" "--export=%ROOT%data\world_export.json" %*
endlocal
