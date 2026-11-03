@echo off
setlocal EnableDelayedExpansion
title RISO ORPHIS FW1230 Uninstaller

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [i] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\uninstall.ps1"
popd
