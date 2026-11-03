# ==============================================================================
# RISO ORPHIS FW1230 - Online 1-Liner PowerShell Installer
# St. Mary School Campus Network
# Usage: irm <URL> | iex
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. ตรวจสอบและขอสิทธิ์ Administrator อัตโนมัติ
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] กำลังร้องขอสิทธิ์ Administrator (UAC)..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/nok99su/Install_RISO/main/setup.ps1' | iex`"" -Verb RunAs
    exit
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "RISO ORPHIS FW1230 - Interactive Installer"

function Show-Banner {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "       RISO ORPHIS FW1230 - Automated Network Installer" -ForegroundColor Yellow
    Write-Host "                St. Mary School Campus Network" -ForegroundColor White
    Write-Host "                 Printer IP: 172.16.40.194" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
}

function Invoke-Installation {
    param([switch]$SetDefault, [switch]$TestPage)

    $tempZip = Join-Path $env:TEMP "RISO_FW1230.zip"
    $tempDir = Join-Path $env:TEMP "RISO_FW1230_Setup"
    $downloadUrl = "https://github.com/nok99su/Install_RISO/releases/download/v1.0.0/RISO_ORPHIS_FW1230_AutoInstaller.zip"

    Write-Host "`n[*] กำลังดาวน์โหลดชุดติดตั้งไดรเวอร์และค่าคอนฟิกจาก GitHub..." -ForegroundColor Cyan
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        Write-Host "[+] ดาวน์โหลดสำเร็จ (ขนาด: $((Get-Item $tempZip).Length / 1MB | ForEach-Object { '{0:N2} MB' -f $_ }))" -ForegroundColor Green
    } catch {
        Write-Host "[-] เกิดข้อผิดพลาดในการดาวน์โหลด: $_" -ForegroundColor Red
        Write-Host "    (หากยังตั้งค่า GitHub เป็น Private กรุณาเปลี่ยนเป็น Public หรือระบุ URL ภายในโรงเรียน)" -ForegroundColor Yellow
        pause
        return
    }

    Write-Host "[*] กำลังแตกไฟล์แพ็กเกจ..." -ForegroundColor Cyan
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

    # ค้นหาโฟลเดอร์โครงการ
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

