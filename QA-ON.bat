@echo off
setlocal EnableDelayedExpansion
set PIDFILE=%TEMP%\qa-watcher.pid
if exist "%PIDFILE%" (
  set /p OLDPID=<"%PIDFILE%"
  tasklist /FI "PID eq !OLDPID!" 2>NUL | find "!OLDPID!" >NUL
  if !ERRORLEVEL!==0 (echo Ya esta activo ^(PID !OLDPID!^). & exit /b)
  del "%PIDFILE%" 2>NUL
)
start "QA-OpenCode" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%USERPROFILE%\opencode-noti\qa-watcher.ps1"
start "QA-HUD" /min powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%USERPROFILE%\opencode-noti\qa-hud.ps1"
echo Activado. Copia un texto y listo.
