@echo off
setlocal
set ROOT=%~dp0..
if "%GODOT_BIN%"=="" set GODOT_BIN=godot.exe
if "%WORLD%"=="" set WORLD=0
if "%PORT%"=="" set PORT=24567
if "%SERVER_NAME%"=="" set SERVER_NAME=My Shadowgrove
if "%PVP%"=="" set PVP=false
if "%ADMIN_FILE%"=="" set ADMIN_FILE=%ROOT%\server\admin_commands.txt

"%GODOT_BIN%" --headless --path "%ROOT%" -- --dedicated --world=%WORLD% --port=%PORT% "--name=%SERVER_NAME%" "--password=%PASSWORD%" --pvp=%PVP% "--admin=%ADMIN_FILE%" %*
endlocal
