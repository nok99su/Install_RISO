# ==============================================================================
# RISO ORPHIS FW1230 - Automated Installer & Configuration Script
# St. Mary School Campus Network
# Target Printer: 172.16.40.194:9100
# ==============================================================================
[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$SetDefault,
    [switch]$TestPage,
    [string]$PrinterIP = "172.16.40.194"
)

# Safety check for PrinterIP
if ([string]::IsNullOrWhiteSpace($PrinterIP) -or $PrinterIP.StartsWith("-")) {
    $PrinterIP = "172.16.40.194"
}

$Host.UI.RawUI.WindowTitle = "RISO ORPHIS FW1230 - Automated Installer"

function Write-Step {
    param([string]$Text)
    Write-Host "`n[+] $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "    [SUCCESS] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "    [WARNING] $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "    [ERROR] $Text" -ForegroundColor Red
}

Write-Host "==================================================================" -ForegroundColor White
Write-Host "       RISO ORPHIS FW1230 - Automated Driver Installer" -ForegroundColor Yellow
Write-Host "                St. Mary School Campus Network" -ForegroundColor White
Write-Host "             Printer IP: $PrinterIP (Port 9100)" -ForegroundColor Gray
Write-Host "==================================================================" -ForegroundColor White

# 1. Check Administrator Privileges
Write-Step "Checking Administrator privileges..."
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "Administrator privileges required. Please run as Administrator."
    if (-not $Silent) {
        Write-Host "`nPress any key to exit..."
        [void][System.Console]::ReadKey()
    }
    exit 1
}
Write-Success "Running with Administrator privileges."

# 2. Check Print Spooler Service
Write-Step "Checking Print Spooler service..."
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if ($spooler.Status -ne "Running") {
    Start-Service -Name Spooler
    Write-Success "Started Print Spooler service."
} else {
    Write-Success "Print Spooler service is running."
}

# 3. Test Network Connection to RISO
$PrinterName = "RISO ORPHIS FW1230"
$PortName = "RISO_$PrinterIP"
$DriverInf = Join-Path $PSScriptRoot "Driver\RISODRV.INF"
$SettingsDat = Join-Path $PSScriptRoot "riso_settings.dat"

Write-Step "Testing network connection to printer ($PrinterIP)..."
$ping = Test-Connection -ComputerName $PrinterIP -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($ping) {
    Write-Success "Printer is ONLINE at $PrinterIP (Ready to print)."
} else {
    Write-Warn "Cannot reach $PrinterIP currently (Printer may be off or PC is not on school network)."
    Write-Warn "Driver and port will still be installed. Once connected to school LAN/Wi-Fi, it will work."
}

# 4. Install Driver to DriverStore
Write-Step "Staging driver package into DriverStore (RISODRV.INF)..."
if (-not (Test-Path $DriverInf)) {
    Write-Err "Driver file not found: $DriverInf"
    exit 1
}

$null = pnputil.exe /add-driver "$DriverInf" /install
Write-Success "Driver package staged in Windows DriverStore."

# 5. Register Driver in Spooler
Write-Step "Registering driver in Windows Spooler..."
try {
    Add-PrinterDriver -Name $PrinterName -ErrorAction Stop
    Write-Success "Registered driver '$PrinterName'."
} catch {
    rundll32.exe printui.dll,PrintUIEntry /ia /m "$PrinterName" /f "$DriverInf" /h "x64" /v "Type 3 - User Mode"
    Write-Success "Registered driver via PrintUI."
}

# 6. Create Standard TCP/IP Port
Write-Step "Configuring Standard TCP/IP Port ($PortName -> $PrinterIP)..."
$existingPort = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
if (-not $existingPort) {
    try {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -PortNumber 9100 -ErrorAction Stop
        Write-Success "Created TCP/IP port $PortName ($PrinterIP:9100)."
    } catch {
        Write-Err "Failed to create printer port: $_"
        exit 1
    }
} else {
    Write-Success "Port $PortName already exists."
}

# 7. Add Printer
Write-Step "Installing printer '$PrinterName'..."
$existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
if (-not $existingPrinter) {
    try {
        Add-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName -PrintProcessor "RC40DPP" -ErrorAction Stop
        Write-Success "Added printer '$PrinterName'."
    } catch {
        Add-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName
        Write-Success "Added printer '$PrinterName'."
    }
} else {
    Set-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName
    Write-Success "Updated existing printer '$PrinterName'."
}

# 8. Restore Configuration Settings
Write-Step "Restoring configuration preset (A4, 2-Sided Duplex, Trays, Monochrome)..."
if (Test-Path $SettingsDat) {
    $proc = Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /Sr /n `"$PrinterName`" /a `"$SettingsDat`" d u g m r f" -Wait -PassThru
    Write-Success "Imported Printing Preferences and Hardware Options."
} else {
    Write-Warn "Configuration file $SettingsDat not found. Skipping."
}

# 9. Set Default Printer
if ($SetDefault) {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
    Write-Success "Set '$PrinterName' as Default Printer."
} elseif (-not $Silent) {
    Write-Host ""
    $setDefaultPrompt = Read-Host "Set '$PrinterName' as Default Printer? (y/n) [Default: n]"
    if ($setDefaultPrompt -eq 'y' -or $setDefaultPrompt -eq 'Y') {
        (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
        Write-Success "Set '$PrinterName' as Default Printer."
    }
}

# 10. Print Test Page
if ($TestPage) {
    if ($ping) {
        rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
        Write-Success "Test page sent to printer."
    } else {
        Write-Warn "Skipped test page because printer is offline."
    }
} elseif (-not $Silent -and $ping) {
    $testPrompt = Read-Host "Print a Test Page now? (y/n) [Default: n]"
    if ($testPrompt -eq 'y' -or $testPrompt -eq 'Y') {
        rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
        Write-Success "Test page sent to printer."
    }
}

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "           [+] INSTALLATION COMPLETED SUCCESSFULLY (100%)" -ForegroundColor Green
Write-Host "       Printer ready for use: $PrinterName" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Green

if (-not $Silent) {
    Write-Host "`nPress any key to close this window..."
    [void][System.Console]::ReadKey()
}
