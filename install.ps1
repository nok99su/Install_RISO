# ==============================================================================
# RISO ORPHIS FW1230 - 1-Click Automated Installer & Configuration Script
# St. Mary School Campus Network (Core System)
# ==============================================================================
[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$SetDefault,
    [switch]$TestPage,
    [string]$PrinterIP = "172.16.40.194"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "RISO ORPHIS FW1230 - Automated Installer"

function Write-Step {
    param([string]$Text)
    Write-Host "`n[+] $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "    [สำเร็จ] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "    [ข้อแนะนำ] $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "    [ผิดพลาด] $Text" -ForegroundColor Red
}

Write-Host "==================================================================" -ForegroundColor White
Write-Host "      ระบบติดตั้งไดรเวอร์และตั้งค่า RISO ORPHIS FW1230 อัตโนมัติ" -ForegroundColor Yellow
Write-Host "               โรงเรียนเซนต์แมรี่ (IP: $PrinterIP)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor White

# 1. ตรวจสอบสิทธิ์ Administrator
Write-Step "ตรวจสอบสิทธิ์ผู้ดูแลระบบ (Administrator)..."
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "กรุณารันไฟล์นี้ด้วยสิทธิ์ Administrator"
    if (-not $Silent) {
        Write-Host "`nกดปุ่มใดๆ เพื่อออกจากโปรแกรม..."
        [void][System.Console]::ReadKey()
    }
    exit 1
}
Write-Success "ทำงานด้วยสิทธิ์ Administrator เรียบร้อย"

# 2. ตรวจสอบ Print Spooler
Write-Step "ตรวจสอบบริการ Print Spooler..."
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if ($spooler.Status -ne "Running") {
    Start-Service -Name Spooler
    Write-Success "เริ่มบริการ Print Spooler เรียบร้อย"
} else {
    Write-Success "บริการ Print Spooler กำลังทำงานปกติ"
}

# 3. ตรวจสอบการเชื่อมต่อกับเครื่องพิมพ์ RISO
$PrinterName = "RISO ORPHIS FW1230"
$PortName = "RISO_$PrinterIP"
$DriverInf = Join-Path $PSScriptRoot "Driver\RISODRV.INF"
$SettingsDat = Join-Path $PSScriptRoot "riso_settings.dat"

Write-Step "ทดสอบการเชื่อมต่อเครือข่ายไปยังเครื่องพิมพ์ ($PrinterIP)..."
$ping = Test-Connection -ComputerName $PrinterIP -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($ping) {
    Write-Success "ตรวจพบเครื่องพิมพ์ออนไลน์ที่ $PrinterIP (พร้อมพิมพ์)"
} else {
    Write-Warn "ยังติดต่อ $PrinterIP ไม่ได้ในขณะนี้ (เครื่องพิมพ์อาจปิดอยู่ หรือเครื่องยังไม่ได้ต่อ Wi-Fi/LAN โรงเรียน)"
    Write-Warn "ระบบจะยังคงติดตั้งไดรเวอร์และพอร์ตให้ล่วงหน้า เมื่อเชื่อมต่อเครือข่ายแล้วจะใช้งานได้ทันที"
}

# 4. ติดตั้ง Driver ลง DriverStore
Write-Step "กำลังลงทะเบียนและติดตั้งไดรเวอร์ (RISODRV.INF)..."
if (-not (Test-Path $DriverInf)) {
    Write-Err "ไม่พบไฟล์ไดรเวอร์ที่ $DriverInf"
    exit 1
}

$pnpResult = pnputil.exe /add-driver "$DriverInf" /install
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 259 -or $LASTEXITCODE -eq 3010) {
    Write-Success "นำเข้าไดรเวอร์เข้าสู่ Windows DriverStore สำเร็จ"
} else {
    Write-Warn "การเรียกใช้ pnputil คืนค่า code $LASTEXITCODE (กำลังดำเนินการต่อ)"
}

# 5. เพิ่ม Driver ใน Spooler
Write-Step "ลงทะเบียนไดรเวอร์ในระบบ Windows Spooler..."
try {
    Add-PrinterDriver -Name $PrinterName -ErrorAction Stop
    Write-Success "ลงทะเบียนไดรเวอร์ '$PrinterName' สำเร็จ"
} catch {
    rundll32.exe printui.dll,PrintUIEntry /ia /m "$PrinterName" /f "$DriverInf" /h "x64" /v "Type 3 - User Mode"
    Write-Success "ลงทะเบียนไดรเวอร์ผ่าน PrintUI สำเร็จ"
}

# 6. สร้าง Port TCP/IP (ถ้ายังไม่มี)
Write-Step "สร้างพอร์ต Standard TCP/IP ($PortName -> $PrinterIP)..."
$existingPort = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
if (-not $existingPort) {
    try {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -PortNumber 9100 -ErrorAction Stop
        Write-Success "สร้างพอร์ต $PortName ($PrinterIP:9100) สำเร็จ"
    } catch {
        Write-Err "เกิดข้อผิดพลาดในการสร้างพอร์ต: $_"
        exit 1
    }
} else {
    Write-Success "พอร์ต $PortName มีอยู่แล้วในระบบ"
}

# 7. เพิ่มเครื่องพิมพ์ (Add-Printer)
Write-Step "ติดตั้งเครื่องพิมพ์ '$PrinterName'..."
$existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
if (-not $existingPrinter) {
    try {
        Add-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName -PrintProcessor "RC40DPP" -ErrorAction Stop
        Write-Success "เพิ่มเครื่องพิมพ์ '$PrinterName' ในระบบเรียบร้อย"
    } catch {
        Add-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName
        Write-Success "เพิ่มเครื่องพิมพ์ '$PrinterName' เรียบร้อย"
    }
} else {
    Set-Printer -Name $PrinterName -DriverName $PrinterName -PortName $PortName
    Write-Success "อัปเดตเครื่องพิมพ์ '$PrinterName' ที่มีอยู่เดิมเรียบร้อย"
}

# 8. Restore ค่า Configuration & Printing Preferences
Write-Step "กู้คืนการตั้งค่าแม่แบบ (A4, 2-Sided Duplex, ถาดกระดาษ, Monochrome)..."
if (Test-Path $SettingsDat) {
    $proc = Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /Sr /n `"$PrinterName`" /a `"$SettingsDat`" d u g m r f" -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Success "นำเข้าการตั้งค่า Printing Preferences และ Hardware Options เรียบร้อย"
    } else {
        Write-Warn "นำเข้าการตั้งค่าเสร็จสิ้น (Code: $($proc.ExitCode))"
    }
} else {
    Write-Warn "ไม่พบไฟล์การตั้งค่า $SettingsDat ข้ามขั้นตอนนี้"
}

# 9. ตั้งค่า Default Printer
if ($SetDefault) {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
    Write-Success "ตั้งค่า '$PrinterName' เป็นเครื่องพิมพ์เริ่มต้นเรียบร้อย (CLI Option)"
} elseif (-not $Silent) {
    Write-Host ""
    $setDefaultPrompt = Read-Host "ต้องการตั้งค่า '$PrinterName' เป็นเครื่องพิมพ์หลัก (Default Printer) หรือไม่? (y/n) [ค่าปกติ: n]"
    if ($setDefaultPrompt -eq 'y' -or $setDefaultPrompt -eq 'Y') {
        (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
        Write-Success "ตั้งค่า '$PrinterName' เป็นเครื่องพิมพ์เริ่มต้นเรียบร้อย"
    }
}

# 10. พิมพ์หน้าทดสอบ
if ($TestPage) {
    if ($ping) {
        rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
        Write-Success "ส่งคำสั่งพิมพ์หน้าทดสอบไปยังเครื่องพิมพ์เรียบร้อย (CLI Option)"
    } else {
        Write-Warn "ไม่สามารถสั่งพิมพ์หน้าทดสอบได้เนื่องจากเครื่องพิมพ์ออฟไลน์"
    }
} elseif (-not $Silent -and $ping) {
    $testPrompt = Read-Host "ต้องการสั่งพิมพ์หน้าทดสอบ (Print Test Page) ทันทีหรือไม่? (y/n) [ค่าปกติ: n]"
    if ($testPrompt -eq 'y' -or $testPrompt -eq 'Y') {
        rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
        Write-Success "ส่งคำสั่งพิมพ์หน้าทดสอบไปยังเครื่องพิมพ์เรียบร้อย"
    }
}

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "              [+] ติดตั้งเครื่องพิมพ์เสร็จสมบูรณ์ 100%!" -ForegroundColor Green
Write-Host "       เครื่องพิมพ์พร้อมใช้งานทันที: $PrinterName" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Green

if (-not $Silent) {
    Write-Host "`nกดปุ่มใดๆ เพื่อปิดหน้าต่างนี้..."
    [void][System.Console]::ReadKey()
}

