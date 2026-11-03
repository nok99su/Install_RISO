# ==============================================================================
# St. Mary School - Network Printers Auto Installer (Unified Hub)
# Printers: RISO ORPHIS FW1230 (172.16.40.194) & Canon iR-ADV 4545i (172.16.40.195)
# Server  : http://172.16.0.3/riso
# Usage   : irm http://172.16.0.3/riso | iex
# ==============================================================================

# Enable TLS 1.2 and bypass ExecutionPolicy for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

# 1. Auto-switch to 64-bit PowerShell if running under 32-bit (x86) on 64-bit Windows
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $nativePs = "$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $nativePs) {
        Write-Host "[*] Switching to 64-bit PowerShell..." -ForegroundColor Yellow
        & $nativePs -NoProfile -ExecutionPolicy Bypass -NoExit -Command "irm 'http://172.16.0.3/riso' | iex"
        exit
    }
}

# 2. Check and request Administrator privileges (UAC) with -NoExit
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[*] Requesting Administrator privileges (UAC)..." -ForegroundColor Yellow
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"irm 'http://172.16.0.3/riso' | iex`"" -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Host "`n[!] Failed to elevate: $_" -ForegroundColor Red
        Write-Host "Please right-click PowerShell and select 'Run as administrator', then re-run the command." -ForegroundColor Yellow
        pause
    }
    exit
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "St. Mary School - Campus Network Printers Installer"

function Show-Banner {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "       St. Mary School - Network Printers Auto Installer" -ForegroundColor Yellow
    Write-Host "                Campus Core Network Infrastructure" -ForegroundColor White
    Write-Host "    [RISO: 172.16.40.194]  |  [Canon iR-ADV 4545i: 172.16.40.195]" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
}

function Invoke-InstallRiso {
    param([switch]$SetDefault, [switch]$TestPage)

    $tempZip = Join-Path $env:TEMP "RISO_FW1230.zip"
    $tempDir = Join-Path $env:TEMP "RISO_FW1230_Setup"
    $localUrl = "http://172.16.0.3/riso/RISO_FW1230.zip"
    $cloudUrl = "https://github.com/nok99su/Install_RISO/releases/download/v1.0.0/RISO_ORPHIS_FW1230_AutoInstaller.zip"

    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "`n>>> [1/2] Installing RISO ORPHIS FW1230 (172.16.40.194) <<<" -ForegroundColor Yellow
    Write-Host "[*] Downloading RISO package..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $localUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 5
        Write-Host "[+] Downloaded from Local Server (172.16.0.3)." -ForegroundColor Green
    } catch {
        Write-Host "[-] Falling back to GitHub Cloud..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $cloudUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 30
    }

    Write-Host "[*] Extracting RISO package..." -ForegroundColor Cyan
    try { Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)
    }

    $installerPath = Join-Path $tempDir "install.ps1"
    if (-not (Test-Path $installerPath)) {
        $sub = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        if ($sub) { $installerPath = Join-Path $sub.FullName "install.ps1" }
    }

    if (Test-Path $installerPath) {
        $argsList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$installerPath`"", "-Silent", "-PrinterIP", "172.16.40.194")
        if ($SetDefault) { $argsList += "-SetDefault" }
        if ($TestPage)   { $argsList += "-TestPage" }
        $p = Start-Process -FilePath "powershell.exe" -ArgumentList $argsList -Wait -PassThru -NoNewWindow
    }

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Invoke-InstallCanon {
    param([switch]$SetDefault, [switch]$TestPage)

    $tempZip = Join-Path $env:TEMP "Canon_4545i.zip"
    $tempDir = Join-Path $env:TEMP "Canon_4545i_Setup"
    $localUrl = "http://172.16.0.3/riso/Canon_4545i.zip"

    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "`n>>> [2/2] Installing Canon imageRUNNER ADVANCE 4545i (172.16.40.195) <<<" -ForegroundColor Yellow
    Write-Host "[*] Downloading Canon 4545i package..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $localUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 15
        Write-Host "[+] Downloaded from Local Server (172.16.0.3)." -ForegroundColor Green
    } catch {
        Write-Host "[-] Download failed: $_" -ForegroundColor Red
        return
    }

    Write-Host "[*] Extracting Canon package..." -ForegroundColor Cyan
    try { Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)
    }

    $inf = Join-Path $tempDir "Driver\CNLB0MA64.INF"
    if (-not (Test-Path $inf)) {
        $found = Get-ChildItem -Path $tempDir -Filter "CNLB0MA64.INF" -Recurse | Select-Object -First 1
        if ($found) { $inf = $found.FullName }
    }

    if (Test-Path $inf) {
        Write-Host "[*] Staging Canon Generic Plus UFR II driver into DriverStore..." -ForegroundColor Cyan
        $pnputil = if (Test-Path "$env:windir\System32\pnputil.exe") { "$env:windir\System32\pnputil.exe" } else { "pnputil.exe" }
        & $pnputil /add-driver "$inf" /install | Out-Null
        
        Write-Host "[*] Registering driver in Spooler..." -ForegroundColor Cyan
        try { Add-PrinterDriver -Name "Canon Generic Plus UFR II" -ErrorAction Stop }
        catch { rundll32.exe printui.dll,PrintUIEntry /ia /m "Canon Generic Plus UFR II" /f "$inf" /h "x64" /v "Type 3 - User Mode" }

        Write-Host "[*] Creating Port (Canon_172.16.40.195)..." -ForegroundColor Cyan
        $portName = "Canon_172.16.40.195"
        if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
            Add-PrinterPort -Name $portName -PrinterHostAddress "172.16.40.195" -PortNumber 9100
        }

        Write-Host "[*] Adding printer 'Canon imageRUNNER ADVANCE 4545i'..." -ForegroundColor Cyan
        $printerName = "Canon imageRUNNER ADVANCE 4545i"
        if (-not (Get-Printer -Name $printerName -ErrorAction SilentlyContinue)) {
            Add-Printer -Name $printerName -DriverName "Canon Generic Plus UFR II" -PortName $portName
        } else {
            Set-Printer -Name $printerName -DriverName "Canon Generic Plus UFR II" -PortName $portName
        }

        # Set default A4 and Two-Sided Long Edge Duplex
        try { Set-PrintConfiguration -PrinterName $printerName -PaperSize A4 -DuplexingMode TwoSidedLongEdge -ErrorAction SilentlyContinue } catch {}

        if ($SetDefault) {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter($printerName)
            Write-Host "[+] Set '$printerName' as Default Printer." -ForegroundColor Green
        }

        if ($TestPage) {
            rundll32.exe printui.dll,PrintUIEntry /k /n "$printerName"
            Write-Host "[+] Test page sent to '$printerName'." -ForegroundColor Green
        }

        Write-Host "[+] Canon imageRUNNER ADVANCE 4545i installed successfully (100%)!" -ForegroundColor Green
    } else {
        Write-Host "[-] Canon INF not found." -ForegroundColor Red
    }

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

while ($true) {
    Show-Banner
    Write-Host ""
    Write-Host "  [1] Install RISO ORPHIS FW1230 (172.16.40.194)" -ForegroundColor Green
    Write-Host "  [2] Install Canon imageRUNNER ADVANCE 4545i (172.16.40.195)" -ForegroundColor Green
    Write-Host "  [3] Install BOTH Printers (All-in-One: RISO + Canon)" -ForegroundColor Cyan
    Write-Host "  [4] Test Network Connection (Ping & Port 9100 for Both)" -ForegroundColor White
    Write-Host "  [5] Print Windows Test Page" -ForegroundColor White
    Write-Host "  [6] Uninstall Printers" -ForegroundColor Yellow
    Write-Host "  [0] Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    $choice = Read-Host "  Please enter your choice [0-6]"

    switch ($choice) {
        "1" {
            Invoke-InstallRiso
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "2" {
            Invoke-InstallCanon
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "3" {
            Invoke-InstallRiso
            Invoke-InstallCanon
            Write-Host "`n[+] Both RISO and Canon installed successfully!" -ForegroundColor Green
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "4" {
            Write-Host "`n[*] Testing RISO ORPHIS FW1230 (172.16.40.194)..." -ForegroundColor Cyan
            $rPing = Test-Connection -ComputerName "172.16.40.194" -Count 2 -Quiet -ErrorAction SilentlyContinue
            Write-Host "    Ping 172.16.40.194: $(if ($rPing) { '[ONLINE]' } else { '[OFFLINE]' })" -ForegroundColor $(if ($rPing) { 'Green' } else { 'Red' })
            
            Write-Host "[*] Testing Canon iR-ADV 4545i (172.16.40.195)..." -ForegroundColor Cyan
            $cPing = Test-Connection -ComputerName "172.16.40.195" -Count 2 -Quiet -ErrorAction SilentlyContinue
            Write-Host "    Ping 172.16.40.195: $(if ($cPing) { '[ONLINE]' } else { '[OFFLINE]' })" -ForegroundColor $(if ($cPing) { 'Green' } else { 'Red' })

            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "5" {
            Write-Host "`nSelect printer to test:" -ForegroundColor Cyan
            Write-Host "  [1] RISO ORPHIS FW1230"
            Write-Host "  [2] Canon imageRUNNER ADVANCE 4545i"
            $tPick = Read-Host "  Choose [1-2]"
            if ($tPick -eq "1") { rundll32.exe printui.dll,PrintUIEntry /k /n "RISO ORPHIS FW1230" }
            elseif ($tPick -eq "2") { rundll32.exe printui.dll,PrintUIEntry /k /n "Canon imageRUNNER ADVANCE 4545i" }
            Write-Host "`nPress any key to return to main menu..." -ForegroundColor Gray
            [void][System.Console]::ReadKey()
            Clear-Host
        }
        "6" {
            Write-Host "`n[*] Uninstalling printers..." -ForegroundColor Yellow
            Remove-Printer -Name "RISO ORPHIS FW1230" -ErrorAction SilentlyContinue
            Remove-Printer -Name "Canon imageRUNNER ADVANCE 4545i" -ErrorAction SilentlyContinue
            Remove-PrinterPort -Name "RISO_172.16.40.194" -ErrorAction SilentlyContinue
            Remove-PrinterPort -Name "Canon_172.16.40.195" -ErrorAction SilentlyContinue
            Write-Host "[+] Printers removed." -ForegroundColor Green
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
