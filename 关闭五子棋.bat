@echo off
if exist "%~dp0dist\WuZiLauncher\WuZiLauncher.exe" (
  "%~dp0dist\WuZiLauncher\WuZiLauncher.exe" --stop
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\stop-wuzi.ps1"
)
if errorlevel 1 pause
