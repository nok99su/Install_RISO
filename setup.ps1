# ==============================================================================
# RISO ORPHIS FW1230 - 1-Liner PowerShell Network Installer
# St. Mary School Campus Network
# Server: http://172.16.0.3/riso  |  GitHub: nok99su/Install_RISO
# ==============================================================================

# Enable TLS 1.2 and bypass ExecutionPolicy for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

# 1. Auto-switch to 64-bit PowerShell if running under 32-bit (x86) on 64-bit Windows
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $nativePs = "$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $nativePs) {
        Write-Host "[*] Switching to 64-bit PowerShell..." -ForegroundColor Yellow
        & $nativePs -NoProfile -ExecutionPolicy Bypass -NoExit -Command "irm 'https://raw.githubusercontent.com/nok99su/Install_RISO/main/setup.ps1' | iex"
        exit
    }
}

# 2. Check and request Administrator privileges (UAC) with -NoExit to prevent instant closing
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[*] Requesting Administrator privileges (UAC)..." -ForegroundColor Yellow
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"irm 'https://raw.githubusercontent.com/nok99su/Install_RISO/main/setup.ps1' | iex`"" -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Host "`n[!] Failed to elevate: $_" -ForegroundColor Red
        Write-Host "Please right-click PowerShell and select 'Run as administrator', then re-run the command." -ForegroundColor Yellow
        pause
    }
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
    $localUrl = "http://172.16.0.3/riso/RISO_FW1230.zip"
    $cloudUrl = "https://github.com/nok99su/Install_RISO/releases/download/v1.0.0/RISO_ORPHIS_FW1230_AutoInstaller.zip"

    # Remove old cached files
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    # Dual-source download: Try Local Server first, fallback to GitHub Cloud
    $downloadSuccess = $false
    Write-Host "`n[*] Attempting download from Local Server (172.16.0.3)..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $localUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 5
        $zipSize = (Get-Item $tempZip).Length / 1MB
        Write-Host ("[+] Downloaded successfully ({0:N2} MB) from Local Server" -f $zipSize) -ForegroundColor Green
        $downloadSuccess = $true
    } catch {
        Write-Host "[-] Local Server unreachable, falling back to GitHub Cloud..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $cloudUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 30
            $zipSize = (Get-Item $tempZip).Length / 1MB
            Write-Host ("[+] Downloaded successfully ({0:N2} MB) from GitHub Cloud" -f $zipSize) -ForegroundColor Green
            $downloadSuccess = $true
        } catch {
            Write-Host "[-] Both Local Server and GitHub download failed: $_" -ForegroundColor Red
            pause
            return
        }
    }

    Write-Host "[*] Extracting installer files..." -ForegroundColor Cyan
    try {
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
    } catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)
    }

    $installerPath = Join-Path $tempDir "install.ps1"
    if (-not (Test-Path $installerPath)) {
        $sub = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        if ($sub) { $installerPath = Join-Path $sub.FullName "install.ps1" }
    }

    if (Test-Path $installerPath) {
        Write-Host "[*] Executing installer with ExecutionPolicy Bypass..." -ForegroundColor Cyan
        $argsList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$installerPath`"", "-Silent", "-PrinterIP", "172.16.40.194")
        if ($SetDefault) { $argsList += "-SetDefault" }
        if ($TestPage)   { $argsList += "-TestPage" }
        
        $p = Start-Process -FilePath "powershell.exe" -ArgumentList $argsList -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            Write-Host "`n[+] Installation finished successfully." -ForegroundColor Green
        } else {
            Write-Host "`n[!] Installer returned code $($p.ExitCode)" -ForegroundColor Yellow
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
            Remove-PrinterPort -Name "RISO_-Silent" -ErrorAction SilentlyContinue
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
