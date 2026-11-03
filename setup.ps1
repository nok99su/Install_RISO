# ==============================================================================
# RISO ORPHIS FW1230 - 1-Liner PowerShell Network Installer
# St. Mary School Campus Network
# Server: http://172.16.0.3/riso
# Usage : irm http://172.16.0.3/riso | iex
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
chcp 65001 >$null 2>&1

# 1. ตรวจสอบและขอสิทธิ์ Administrator (UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[*] กำลังร้องขอสิทธิ์ Administrator (UAC)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'http://172.16.0.3/riso' | iex`"" -Verb RunAs
    exit
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "RISO ORPHIS FW1230 - School Network Installer"

function Show-Banner {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "      RISO ORPHIS FW1230 - School Network Auto Installer" -ForegroundColor Yellow
    Write-Host "                St. Mary School Campus Network" -ForegroundColor White
    Write-Host "      Server: 172.16.0.3  |  Printer IP: 172.16.40.194" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
}

function Invoke-Installation {
    param([switch]$SetDefault, [switch]$TestPage)

    $tempZip = Join-Path $env:TEMP "RISO_FW1230.zip"
    $tempDir = Join-Path $env:TEMP "RISO_FW1230_Setup"
    $downloadUrl = "http://172.16.0.3/riso/RISO_FW1230.zip"

    Write-Host "`n[*] กำลังดึงแพ็กเกจติดตั้งจาก Server 172.16.0.3..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        $zipSize = (Get-Item $tempZip).Length / 1MB
        Write-Host ("[+] ดาวน์โหลดสำเร็จ ({0:N2} MB) จาก Local Server" -f $zipSize) -ForegroundColor Green
    } catch {
        Write-Host "[-] เกิดข้อผิดพลาดในการดาวน์โหลด: $_" -ForegroundColor Red
        Write-Host "    กรุณาตรวจสอบว่าเชื่อมต่อ Wi-Fi หรือ LAN ของโรงเรียนอยู่หรือไม่" -ForegroundColor Yellow
        pause
        return
    }

    Write-Host "[*] กำลังคลี่ไฟล์แพ็กเกจ..." -ForegroundColor Cyan
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

    $installerPath = Join-Path $tempDir "install.ps1"
    if (-not (Test-Path $installerPath)) {
        $sub = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        if ($sub) { $installerPath = Join-Path $sub.FullName "install.ps1" }
    }

    if (Test-Path $installerPath) {
        $argsList = @("-Silent")
        if ($SetDefault) { $argsList += "-SetDefault" }
        if ($TestPage)   { $argsList += "-TestPage" }
        
        & $installerPath @argsList
    } else {
        Write-Host "[-] ไม่พบไฟล์ install.ps1 ในแพ็กเกจ" -ForegroundColor Red
    }

    # ทำความสะอาดไฟล์ชั่วคราว
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

while ($true) {
    Show-Banner
    Write-Host ""
    Write-Host "  [1] ติดตั้งไดรเวอร์ + ตั้งค่าอัตโนมัติ (Recommended)" -ForegroundColor Green
    Write-Host "  [2] ติดตั้ง + ตั้งเป็นเครื่องพิมพ์หลัก (Install & Set as Default)" -ForegroundColor Green
    Write-Host "  [3] ทดสอบการเชื่อมต่อ (Ping 172.16.40.194 & Check Port 9100)" -ForegroundColor White
    Write-Host "  [4] สั่งพิมพ์หน้าทดสอบ (Print Test Page)" -ForegroundColor White
    Write-Host "  [5] ถอนการติดตั้ง RISO ออกจากเครื่องนี้ (Uninstall)" -ForegroundColor Yellow
    Write-Host "  [0] ออกจากโปรแกรม (Exit)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    $choice = Read-Host "  กรุณาเลือกเมนู [0-5]"

    switch ($choice) {
        "1" {
            Invoke-Installation
            Write-Host "`nกดปุ่มใดๆ เพื่อกลับสู่เมนูหลัก..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "2" {
            Invoke-Installation -SetDefault
            Write-Host "`nกดปุ่มใดๆ เพื่อกลับสู่เมนูหลัก..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "3" {
            Write-Host "`n[*] ทดสอบ Ping ไปยัง 172.16.40.194..." -NoNewline
            $p = Test-Connection -ComputerName "172.16.40.194" -Count 2 -Quiet -ErrorAction SilentlyContinue
            if ($p) { Write-Host " [ONLINE]" -ForegroundColor Green } else { Write-Host " [OFFLINE]" -ForegroundColor Red }
            
            Write-Host "[*] ทดสอบ TCP Port 9100 (RAW)..." -NoNewline
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $iar = $tcp.BeginConnect("172.16.40.194", 9100, $null, $null)
                if ($iar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) {
                    $tcp.Close()
                    Write-Host " [OPEN / READY]" -ForegroundColor Green
                } else {
                    $tcp.Close()
                    Write-Host " [CLOSED / TIMEOUT]" -ForegroundColor Yellow
                }
            } catch {
                Write-Host " [ERROR]" -ForegroundColor Red
            }
            Write-Host "`nกดปุ่มใดๆ เพื่อกลับสู่เมนูหลัก..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "4" {
            Write-Host "`n[*] กำลังส่งคำสั่งพิมพ์ Test Page ไปยัง RISO ORPHIS FW1230..." -ForegroundColor Cyan
            rundll32.exe printui.dll,PrintUIEntry /k /n "RISO ORPHIS FW1230"
            Write-Host "[+] ส่งคำสั่งพิมพ์เรียบร้อยแล้ว" -ForegroundColor Green
            Write-Host "`nกดปุ่มใดๆ เพื่อกลับสู่เมนูหลัก..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "5" {
            Write-Host "`n[*] กำลังถอนการติดตั้ง..." -ForegroundColor Yellow
            Remove-Printer -Name "RISO ORPHIS FW1230" -ErrorAction SilentlyContinue
            Remove-PrinterPort -Name "RISO_172.16.40.194" -ErrorAction SilentlyContinue
            try { Remove-PrinterDriver -Name "RISO ORPHIS FW1230" -ErrorAction Stop } catch {}
            Write-Host "[+] ถอนการติดตั้งเรียบร้อยแล้ว" -ForegroundColor Green
            Write-Host "`nกดปุ่มใดๆ เพื่อกลับสู่เมนูหลัก..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "0" {
            Write-Host "`nออกจากโปรแกรม เรียบร้อยครับ`n" -ForegroundColor White
            exit
        }
        default {
            Clear-Host
        }
    }
}
