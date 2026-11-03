# ==============================================================================
# RISO ORPHIS FW1230 - Uninstaller Script
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "RISO ORPHIS FW1230 - Uninstaller"

$PrinterName = "RISO ORPHIS FW1230"
$PortName = "RISO_172.16.40.194"

Write-Host "==================================================================" -ForegroundColor White
Write-Host "         ระบบถอนการติดตั้ง RISO ORPHIS FW1230 อัตโนมัติ" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor White

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ผิดพลาด] กรุณารันด้วยสิทธิ์ Administrator" -ForegroundColor Red
    pause
    exit 1
}

$confirm = Read-Host "ยืนยันการลบเครื่องพิมพ์ '$PrinterName' ออกจากเครื่องนี้หรือไม่? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "ยกเลิกการถอนการติดตั้ง" -ForegroundColor Yellow
    exit 0
}

# 1. ลบเครื่องพิมพ์
if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
    Remove-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    Write-Host "[OK] ลบเครื่องพิมพ์ $PrinterName เรียบร้อย" -ForegroundColor Green
} else {
    Write-Host "[i] ไม่พบเครื่องพิมพ์ $PrinterName" -ForegroundColor Gray
}

# 2. ลบพอร์ต
if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
    Remove-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    Write-Host "[OK] ลบพอร์ต $PortName เรียบร้อย" -ForegroundColor Green
} else {
    Write-Host "[i] ไม่พบพอร์ต $PortName" -ForegroundColor Gray
}

# 3. ลบไดรเวอร์ (ถ้าไม่มีเครื่องอื่นใช้)
try {
    Remove-PrinterDriver -Name $PrinterName -ErrorAction Stop
    Write-Host "[OK] ลบไดรเวอร์ $PrinterName ออกจาก Spooler เรียบร้อย" -ForegroundColor Green
} catch {
    Write-Host "[i] ไม่สามารถลบไดรเวอร์ได้ (อาจมีเครื่องพิมพ์อื่นใช้งานอยู่)" -ForegroundColor Gray
}

Write-Host "`nถอนการติดตั้งเสร็จสิ้นเรียบร้อยแล้ว!" -ForegroundColor Green
Write-Host "กดปุ่มใดๆ เพื่อปิดหน้าต่าง..."
[void][System.Console]::ReadKey()

