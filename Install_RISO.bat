@echo off
setlocal EnableDelayedExpansion
title RISO ORPHIS FW1230 Auto Installer

:: ตรวจสอบสิทธิ์ Admin ถ้าไม่ใช่จะขอสิทธิ์ (UAC prompt) อัตโนมัติทันที
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [i] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    exit /b
)

:: รองรับการเปิดใช้งานจาก Network Share (UNC Path: \\Server\Share) ผ่าน pushd
pushd "%~dp0"

:: ส่งค่า Arguments ทั้งหมดต่อไปยัง PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File ".\install.ps1" %*

popd
