@echo off
title Los Santos Life - FiveM Server
cd /d "%~dp0server-data"
echo Starte FiveM Server (server.cfg)...
"%~dp0FXServer.exe" +exec server.cfg
pause
