# ==============================================================================
# RISO ORPHIS FW1230 - 1-Liner PowerShell Network Installer
# St. Mary School Campus Network
# Server: http://172.16.0.3/riso
# Usage : irm http://172.16.0.3/riso | iex
# ==============================================================================

# 1. Check and request Administrator privileges (UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[*] Requesting Administrator privileges (UAC)..." -ForegroundColor Yellow
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

    Write-Host "`n[*] Downloading package from Server 172.16.0.3..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        $zipSize = (Get-Item $tempZip).Length / 1MB
        Write-Host ("[+] Downloaded successfully ({0:N2} MB) from local server" -f $zipSize) -ForegroundColor Green
    } catch {
        Write-Host "[-] Download error: $_" -ForegroundColor Red
        Write-Host "    Please ensure you are connected to School Wi-Fi or LAN." -ForegroundColor Yellow
        pause
        return
    }

    Write-Host "[*] Extracting installer files..." -ForegroundColor Cyan
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

    $installerPath = Join-Path $tempDir "install.ps1"
    if (-not (Test-Path $installerPath)) {
        $sub = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        if ($sub) { $installerPath = Join-Path $sub.FullName "install.ps1" }
    }

    if (Test-Path $installerPath) {
        if ($SetDefault) {
            & $installerPath -Silent -SetDefault -PrinterIP "172.16.40.194"
        } elseif ($TestPage) {
            & $installerPath -Silent -TestPage -PrinterIP "172.16.40.194"
        } else {
            & $installerPath -Silent -PrinterIP "172.16.40.194"
        }
    } else {
        Write-Host "[-] install.ps1 not found in package" -ForegroundColor Red
    }

    # Clean up temporary files
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

while ($true) {
    Show-Banner
    Write-Host ""
    Write-Host "  [1] Install Driver & Clone Settings (Recommended)" -ForegroundColor Green
    Write-Host "  [2] Install & Set as Default Printer" -ForegroundColor Green
    Write-Host "  [3] Test Network Connection (Ping & Port 9100)" -ForegroundColor White
    Write-Host "  [4] Print Windows Test Page" -ForegroundColor White
    Write-Host "  [5] Uninstall RISO Printer" -ForegroundColor Yellow
    Write-Host "  [0] Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    $choice = Read-Host "  Please enter your choice [0-5]"

    switch ($choice) {
        "1" {
            Invoke-Installation
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "2" {
            Invoke-Installation -SetDefault
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "3" {
            Write-Host "`n[*] Pinging 172.16.40.194..." -NoNewline
            $p = Test-Connection -ComputerName "172.16.40.194" -Count 2 -Quiet -ErrorAction SilentlyContinue
            if ($p) { Write-Host " [ONLINE]" -ForegroundColor Green } else { Write-Host " [OFFLINE]" -ForegroundColor Red }
            
            Write-Host "[*] Testing TCP Port 9100 (RAW)..." -NoNewline
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
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "4" {
            Write-Host "`n[*] Sending Test Page to RISO ORPHIS FW1230..." -ForegroundColor Cyan
            rundll32.exe printui.dll,PrintUIEntry /k /n "RISO ORPHIS FW1230"
            Write-Host "[+] Test page sent successfully." -ForegroundColor Green
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "5" {
            Write-Host "`n[*] Uninstalling RISO..." -ForegroundColor Yellow
            Remove-Printer -Name "RISO ORPHIS FW1230" -ErrorAction SilentlyContinue
            Remove-PrinterPort -Name "RISO_172.16.40.194" -ErrorAction SilentlyContinue
            try { Remove-PrinterDriver -Name "RISO ORPHIS FW1230" -ErrorAction Stop } catch {}
            Write-Host "[+] Uninstalled successfully." -ForegroundColor Green
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "0" {
            Write-Host "`nExiting installer. Have a nice day!`n" -ForegroundColor White
            exit
        }
        default {
            Clear-Host
        }
    }
}
