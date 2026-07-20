@echo off
if exist "%~dp0dist\WuZiLauncher\WuZiLauncher.exe" (
  start "" "%~dp0dist\WuZiLauncher\WuZiLauncher.exe"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\launch-wuzi.ps1"
)
if errorlevel 1 pause
