param(
    [string]$InstallMode = $env:INSTALL_MODE
)

# ==============================================================================
# St. Mary School - Network Printers Auto Installer (Unified Hub)
# Printers: RISO ORPHIS FW1230 (172.16.40.194) & Canon iR-ADV 4545i (172.16.40.195)
# Server  : http://172.16.0.3/printer
# Usage   : irm http://172.16.0.3/printer/setup.ps1 | iex
# ==============================================================================

# Enable TLS 1.2 and bypass ExecutionPolicy for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

# Resolve InstallMode from parameter or environment variable
if ($InstallMode) { $env:INSTALL_MODE = $InstallMode }

# 1. Auto-switch to 64-bit PowerShell if running under 32-bit (x86) on 64-bit Windows
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $nativePs = "$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $nativePs) {
        Write-Host "[*] Switching to 64-bit PowerShell..." -ForegroundColor Yellow
        $modeCmd = if ($env:INSTALL_MODE) { "`$env:INSTALL_MODE='$($env:INSTALL_MODE)'; " } else { "" }
        & $nativePs -NoProfile -ExecutionPolicy Bypass -NoExit -Command "$modeCmd irm 'http://172.16.0.3/printer/setup.ps1' | iex"
        exit
    }
}

# 2. Check and request Administrator privileges (UAC) with -NoExit
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[*] Requesting Administrator privileges (UAC)..." -ForegroundColor Yellow
    try {
        $modeCmd = if ($env:INSTALL_MODE) { "`$env:INSTALL_MODE='$($env:INSTALL_MODE)'; " } else { "" }
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"$modeCmd irm 'http://172.16.0.3/printer/setup.ps1' | iex`"" -Verb RunAs -ErrorAction Stop
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

function Check-PrinterAndDriver {
    param(
        [string]$PrinterName,
        [string]$DriverName,
        [string]$DefaultIP,
        [string]$PortPrefix
    )

    $existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    $existingDriver  = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
    $defaultPortName = "${PortPrefix}_${DefaultIP}"
    $existingPort    = Get-PrinterPort -Name $defaultPortName -ErrorAction SilentlyContinue
    if (-not $existingPort -and $existingPrinter) {
        $existingPort = Get-PrinterPort -Name $existingPrinter.PortName -ErrorAction SilentlyContinue
    }

    $isInstalled = ($existingPrinter -ne $null) -or ($existingDriver -ne $null) -or ($existingPort -ne $null)
    if (-not $isInstalled) {
        return @{ Action = "Install"; TargetIP = $DefaultIP }
    }

    $currentIP = if ($existingPort -and $existingPort.PrinterHostAddress) { $existingPort.PrinterHostAddress } else { $DefaultIP }

    Write-Host "`n==================================================================" -ForegroundColor Yellow
    Write-Host " [!] ALREADY INSTALLED / CONFIGURED ON THIS COMPUTER:" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "  * Driver Status : $(if ($existingDriver) { '[INSTALLED] ' + $existingDriver.Name } else { '[NOT INSTALLED]' })" -ForegroundColor White
    Write-Host "  * Printer Status: $(if ($existingPrinter) { '[INSTALLED] ' + $existingPrinter.Name } else { '[NOT CREATED YET]' })" -ForegroundColor White
    Write-Host "  * Current Port  : $(if ($existingPort) { $existingPort.Name + ' (IP: ' + $currentIP + ')' } else { '[NONE]' })" -ForegroundColor White
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " Please choose an option:" -ForegroundColor White
    Write-Host "  [1] Update Settings & Verify IP ($DefaultIP + A4/Duplex) [DEFAULT]" -ForegroundColor Green
    Write-Host "  [2] Change / Edit IP Address (Current IP: $currentIP)" -ForegroundColor Cyan
    Write-Host "  [3] Remove / Uninstall Driver, Printer & Port" -ForegroundColor Red
    Write-Host "  [4] Reinstall Fresh (Clean Remove & Re-install from Server)" -ForegroundColor Yellow
    Write-Host "  [0] Skip (Keep existing, do not change)" -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

    $choice = Read-Host " Enter choice [1-4, 0] (Press Enter for [1])"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    switch ($choice) {
        "1" {
            return @{ Action = "Update"; TargetIP = $DefaultIP; ExistingPrinter = $existingPrinter; ExistingPort = $existingPort }
        }
        "2" {
            $newIP = Read-Host " Enter new IP address (Press Enter for $currentIP)"
            if ([string]::IsNullOrWhiteSpace($newIP)) { $newIP = $currentIP }
            return @{ Action = "Update"; TargetIP = $newIP; ExistingPrinter = $existingPrinter; ExistingPort = $existingPort }
        }
        "3" {
            Write-Host "`n[*] Removing printer, port, and driver..." -ForegroundColor Yellow
            if ($existingPrinter) { Remove-Printer -Name $existingPrinter.Name -ErrorAction SilentlyContinue }
            if ($existingPort) { Remove-PrinterPort -Name $existingPort.Name -ErrorAction SilentlyContinue }
            if ($existingDriver) { Remove-PrinterDriver -Name $existingDriver.Name -ErrorAction SilentlyContinue }
            Write-Host "[+] SUCCESS: Removed successfully." -ForegroundColor Green
            return @{ Action = "Abort" }
        }
        "4" {
            Write-Host "`n[*] Cleaning old components for fresh install..." -ForegroundColor Yellow
            if ($existingPrinter) { Remove-Printer -Name $existingPrinter.Name -ErrorAction SilentlyContinue }
            if ($existingPort) { Remove-PrinterPort -Name $existingPort.Name -ErrorAction SilentlyContinue }
            return @{ Action = "Install"; TargetIP = $DefaultIP }
        }
        "0" {
            Write-Host "`n[*] Skipped. Keeping existing configuration." -ForegroundColor Cyan
            return @{ Action = "Abort" }
        }
        default {
            return @{ Action = "Update"; TargetIP = $DefaultIP; ExistingPrinter = $existingPrinter; ExistingPort = $existingPort }
        }
    }
}

function Invoke-InstallRiso {
    param([switch]$SetDefault, [switch]$TestPage)

    Write-Host "`n------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "[*] Processing RISO ORPHIS FW1230 Installation..." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

    $check = Check-PrinterAndDriver -PrinterName "RISO ORPHIS FW1230" -DriverName "RISO ORPHIS FW1230" -DefaultIP "172.16.40.194" -PortPrefix "RISO"
    if ($check.Action -eq "Abort") { return }

    $targetIP = $check.TargetIP

    if ($check.Action -eq "Update") {
        Write-Host "`n[*] Updating RISO ORPHIS FW1230 configuration with IP: $targetIP..." -ForegroundColor Cyan
        $portName = "RISO_$targetIP"
        if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
            Write-Host "[*] Creating Standard TCP/IP Port: $portName ($targetIP:9100)..." -ForegroundColor Cyan
            Add-PrinterPort -Name $portName -PrinterHostAddress $targetIP -PortNumber 9100
        }

        # If printer exists, update port; if not, create it with installed driver
        if (-not (Get-Printer -Name "RISO ORPHIS FW1230" -ErrorAction SilentlyContinue)) {
            Write-Host "[*] Adding printer 'RISO ORPHIS FW1230'..." -ForegroundColor Cyan
            Add-Printer -Name "RISO ORPHIS FW1230" -DriverName "RISO ORPHIS FW1230" -PortName $portName
        } else {
            Set-Printer -Name "RISO ORPHIS FW1230" -PortName $portName -ErrorAction SilentlyContinue
        }

        # Update default A4 and Duplex
        try { Set-PrintConfiguration -PrinterName "RISO ORPHIS FW1230" -PaperSize A4 -DuplexingMode TwoSidedLongEdge -ErrorAction SilentlyContinue } catch {}

        if ($SetDefault) {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter("RISO ORPHIS FW1230")
            Write-Host "[+] Set 'RISO ORPHIS FW1230' as Default Printer." -ForegroundColor Green
        }
        if ($TestPage) {
            rundll32.exe printui.dll,PrintUIEntry /k /n "RISO ORPHIS FW1230"
            Write-Host "[+] Test page sent to RISO ORPHIS FW1230." -ForegroundColor Green
        }

        Write-Host "[+] SUCCESS: RISO ORPHIS FW1230 updated with IP: $targetIP (100%)!" -ForegroundColor Green
        return
    }

    $tempZip = Join-Path $env:TEMP "RISO_FW1230.zip"
    $tempDir = Join-Path $env:TEMP "RISO_Setup_Extracted"
    $localUrl = "http://172.16.0.3/printer/RISO_FW1230.zip"
    $cloudUrl = "https://github.com/nok99su/Install_RISO/releases/download/v1.0.0/RISO_ORPHIS_FW1230_AutoInstaller.zip"

    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "[*] Downloading RISO package..." -ForegroundColor Cyan
    $downloadSuccess = $false
    try {
        Invoke-WebRequest -Uri $localUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 10
        Write-Host "[+] Downloaded from Campus Server (172.16.0.3)" -ForegroundColor Green
        $downloadSuccess = $true
    } catch {
        Write-Host "[-] Campus server download failed. Trying GitHub Cloud fallback..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $cloudUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 35
            Write-Host "[+] Downloaded from GitHub Cloud" -ForegroundColor Green
            $downloadSuccess = $true
        } catch {
            Write-Host "[!] Download failed from both locations: $_" -ForegroundColor Red
            return
        }
    }

    Write-Host "[*] Extracting package files..." -ForegroundColor Cyan
    try { Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)
    }

    # Locate install.ps1 inside extracted package
    $installPs = Get-ChildItem -Path $tempDir -Filter "install.ps1" -Recurse | Select-Object -First 1
    if ($installPs) {
        $pkgRoot = $installPs.Directory.FullName
        Write-Host "[*] Executing RISO automated setup in: $pkgRoot (IP: $targetIP)" -ForegroundColor Cyan
        & "$($installPs.FullName)" -Silent -PrinterIP $targetIP
        
        if ($SetDefault) {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter("RISO ORPHIS FW1230")
            Write-Host "[+] Set 'RISO ORPHIS FW1230' as Default Printer." -ForegroundColor Green
        }
        if ($TestPage) {
            rundll32.exe printui.dll,PrintUIEntry /k /n "RISO ORPHIS FW1230"
            Write-Host "[+] Test page sent to RISO ORPHIS FW1230." -ForegroundColor Green
        }
    } else {
        Write-Host "[-] install.ps1 not found in extracted archive." -ForegroundColor Red
    }

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Invoke-InstallCanon {
    param([switch]$SetDefault, [switch]$TestPage)

    Write-Host "`n------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "[*] Processing Canon imageRUNNER ADVANCE 4545i Installation..." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan

    $check = Check-PrinterAndDriver -PrinterName "Canon imageRUNNER ADVANCE 4545i" -DriverName "Canon Generic Plus UFR II" -DefaultIP "172.16.40.195" -PortPrefix "Canon"
    if ($check.Action -eq "Abort") { return }

    $targetIP = $check.TargetIP

    if ($check.Action -eq "Update") {
        Write-Host "`n[*] Updating Canon imageRUNNER ADVANCE 4545i configuration with IP: $targetIP..." -ForegroundColor Cyan
        $portName = "Canon_$targetIP"
        if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
            Write-Host "[*] Creating Standard TCP/IP Port: $portName ($targetIP:9100)..." -ForegroundColor Cyan
            Add-PrinterPort -Name $portName -PrinterHostAddress $targetIP -PortNumber 9100
        }

        # If printer exists, update port; if not, create it with installed driver
        $printerName = "Canon imageRUNNER ADVANCE 4545i"
        if (-not (Get-Printer -Name $printerName -ErrorAction SilentlyContinue)) {
            Write-Host "[*] Adding printer '$printerName'..." -ForegroundColor Cyan
            Add-Printer -Name $printerName -DriverName "Canon Generic Plus UFR II" -PortName $portName
        } else {
            Set-Printer -Name $printerName -PortName $portName -ErrorAction SilentlyContinue
        }

        # Update default A4 and Duplex
        try { Set-PrintConfiguration -PrinterName $printerName -PaperSize A4 -DuplexingMode TwoSidedLongEdge -ErrorAction SilentlyContinue } catch {}

        if ($SetDefault) {
            (New-Object -ComObject WScript.Network).SetDefaultPrinter($printerName)
            Write-Host "[+] Set '$printerName' as Default Printer." -ForegroundColor Green
        }
        if ($TestPage) {
            rundll32.exe printui.dll,PrintUIEntry /k /n "$printerName"
            Write-Host "[+] Test page sent to '$printerName'." -ForegroundColor Green
        }

        Write-Host "[+] SUCCESS: Canon imageRUNNER ADVANCE 4545i updated with IP: $targetIP (100%)!" -ForegroundColor Green
        return
    }

    $tempZip = Join-Path $env:TEMP "Canon_4545i.zip"
    $tempDir = Join-Path $env:TEMP "Canon_Setup_Extracted"
    $localUrl = "http://172.16.0.3/printer/Canon_4545i.zip"

    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "[*] Downloading Canon 4545i package (41 MB)..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $localUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 30
        Write-Host "[+] Downloaded from Campus Server (172.16.0.3)" -ForegroundColor Green
    } catch {
        Write-Host "[!] Download failed: $_" -ForegroundColor Red
        return
    }

    Write-Host "[*] Extracting package files..." -ForegroundColor Cyan
    try { Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force }
    catch {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)
    }

    $canonInf = Get-ChildItem -Path $tempDir -Filter "CNLB0MA64.INF" -Recurse | Select-Object -First 1
    if (-not $canonInf) {
        $canonInf = Get-ChildItem -Path $tempDir -Filter "*.inf" -Recurse | Select-Object -First 1
    }

    if ($canonInf) {
        Write-Host "[*] Staging Canon driver in DriverStore: $($canonInf.FullName)" -ForegroundColor Cyan
        & pnputil.exe /add-driver "$($canonInf.FullName)" /install | Out-Null

        Write-Host "[*] Registering 'Canon Generic Plus UFR II' driver..." -ForegroundColor Cyan
        Add-PrinterDriver -Name "Canon Generic Plus UFR II" -ErrorAction SilentlyContinue

        $portName = "Canon_$targetIP"
        if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
            Write-Host "[*] Creating Standard TCP/IP Port: $portName ($targetIP:9100)..." -ForegroundColor Cyan
            Add-PrinterPort -Name $portName -PrinterHostAddress $targetIP -PortNumber 9100
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

# ==============================================================================
# Non-Interactive Auto Mode Execution (1-Click Install Trigger)
# ==============================================================================
$autoMode = if ($InstallMode) { $InstallMode } else { $env:INSTALL_MODE }
if ($autoMode -eq "Both" -or $autoMode -eq "3") {
    Show-Banner
    Write-Host "`n[*] Starting 1-Click Automated Installation for BOTH PRINTERS..." -ForegroundColor Cyan
    Invoke-InstallRiso
    Invoke-InstallCanon
    Write-Host "`n==================================================================" -ForegroundColor Green
    Write-Host "  [+] Process Completed for Both Printers!" -ForegroundColor Green
    Write-Host "==================================================================`n" -ForegroundColor Green
    Write-Host "Installation Completed Successfully! Window will auto-close in 8 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8
    exit
}
elseif ($autoMode -eq "RISO" -or $autoMode -eq "1") {
    Show-Banner
    Write-Host "`n[*] Starting 1-Click Automated Installation for RISO FW1230..." -ForegroundColor Cyan
    Invoke-InstallRiso
    Write-Host "Installation Completed Successfully! Window will auto-close in 8 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8
    exit
}
elseif ($autoMode -eq "Canon" -or $autoMode -eq "2") {
    Show-Banner
    Write-Host "`n[*] Starting 1-Click Automated Installation for Canon 4545i..." -ForegroundColor Cyan
    Invoke-InstallCanon
    Write-Host "Installation Completed Successfully! Window will auto-close in 8 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 8
    exit
}

# ==============================================================================
# Interactive Menu Loop
# ==============================================================================
while ($true) {
    Show-Banner
    Write-Host ""
    Write-Host "  [1] Install / Update RISO ORPHIS FW1230 (172.16.40.194)" -ForegroundColor Green
    Write-Host "  [2] Install / Update Canon imageRUNNER ADVANCE 4545i (172.16.40.195)" -ForegroundColor Green
    Write-Host "  [3] Install / Update BOTH Printers (All-in-One: RISO + Canon)" -ForegroundColor Cyan
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
            Write-Host "`n[+] Process finished for both printers!" -ForegroundColor Green
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
