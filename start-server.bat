@echo off
setlocal
title Los Santos Life - FiveM Server
cd /d "%~dp0server-data"

rem --- Lizenzdatei anlegen, falls sie noch fehlt ---
if not exist license.cfg (
    copy license.example.cfg license.cfg >nul
    goto :missingkey
)

rem --- Pruefen, ob der Lizenzschluessel schon eingetragen wurde ---
findstr /C:"DEIN_LIZENZKEY_HIER" license.cfg >nul 2>&1
if not errorlevel 1 goto :missingkey
goto :start

:missingkey
echo.
echo ================================================================
echo   Der Lizenzschluessel fehlt noch - der Server kann so nicht starten.
echo ================================================================
echo.
echo   1. https://keymaster.fivem.net im Browser oeffnen und einloggen
echo      ^(kostenloses Cfx.re-Konto, ggf. erstellen^)
echo   2. "New Server" anklicken, einen Key erstellen und kopieren
echo   3. In dieser Datei den Key eintragen:
echo         server-data\license.cfg
echo      Zeile suchen:
echo         sv_licenseKey "DEIN_LIZENZKEY_HIER"
echo      ersetzen durch:
echo         sv_licenseKey "dein-echter-key"
echo   4. Diese start-server.bat erneut ausfuehren
echo.
echo   Der Key ist kostenlos und nur fuer diesen Server gedacht.
echo   license.cfg wird nicht in Git eingecheckt.
echo.
pause
exit /b 1

:start
echo Starte FiveM Server (server.cfg)...
echo Verbinden im Spiel mit:  connect localhost:30120
echo.
"%~dp0FXServer.exe" +exec server.cfg
pause
