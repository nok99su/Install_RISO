# ==============================================================================
# RISO ORPHIS FW1230 - Command Line Controller (CLI)
# St. Mary School Campus Network
# ==============================================================================
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Command = "help",

    [Parameter(Position=1)]
    [string]$Target = "",

    [string]$PrinterIP = "172.16.40.194",
    [string]$PrinterName = "RISO ORPHIS FW1230"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Header {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "         RISO ORPHIS FW1230 - Command Line Controller" -ForegroundColor Yellow
    Write-Host "                  Target IP: $PrinterIP (Port 9100)" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
}

function Test-RisoPing {
    Write-Host "[*] กำลังทดสอบ Ping ไปยัง $PrinterIP..." -NoNewline
    $ping = Test-Connection -ComputerName $PrinterIP -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($ping) {
        Write-Host " [ONLINE]" -ForegroundColor Green
        return $true
    } else {
        Write-Host " [OFFLINE / UNREACHABLE]" -ForegroundColor Red
        return $false
    }
}

function Test-RisoPort {
    Write-Host "[*] กำลังทดสอบ TCP Port 9100 (RAW Print)..." -NoNewline
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($PrinterIP, 9100, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne(2000, $false)
        if ($success -and $tcp.Connected) {
            $tcp.EndConnect($iar)
            $tcp.Close()
            Write-Host " [OPEN / READY]" -ForegroundColor Green
            return $true
        } else {
            $tcp.Close()
            Write-Host " [PORT CLOSED OR TIMEOUT]" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host " [ERROR: $_]" -ForegroundColor Red
        return $false
    }
}

function Show-Help {
    Show-Header
    Write-Host "วิธีใช้งานคำสั่ง:  riso <คำสั่ง> [พารามิเตอร์]" -ForegroundColor White
    Write-Host ""
    Write-Host "คำสั่งที่มีให้ใช้งาน:" -ForegroundColor Yellow
    Write-Host "  riso ping                - ทดสอบ Ping และพอร์ต 9100 ของเครื่องพิมพ์" -ForegroundColor White
    Write-Host "  riso check / status      - ตรวจสอบสถานะการเชื่อมต่อ และสถานะใน Windows" -ForegroundColor White
    Write-Host "  riso test                - ยิงพิมพ์หน้าทดสอบ (Test Page) ไปยังเครื่องพิมพ์ทันที" -ForegroundColor White
    Write-Host "  riso print <file_path>   - สั่งพิมพ์ไฟล์เอกสาร (PDF, DOCX, TXT, รูปภาพ) ออก RISO ทันที" -ForegroundColor White
    Write-Host "  riso queue / jobs        - ดูรายการเอกสารที่กำลังเข้าคิวรอพิมพ์" -ForegroundColor White
    Write-Host "  riso clear               - ยกเลิกและลบคิวงานพิมพ์ที่ค้างอยู่ทั้งหมด" -ForegroundColor White
    Write-Host "  riso default             - กำหนดให้ RISO เป็นเครื่องพิมพ์เริ่มต้น (Default Printer)" -ForegroundColor White
    Write-Host "  riso restart             - รีสตาร์ทบริการ Print Spooler แก้ปัญหาคิวพิมพ์ค้าง" -ForegroundColor White
    Write-Host "  riso install             - สั่งรันการติดตั้งไดรเวอร์และตั้งค่าแบบอัตโนมัติ" -ForegroundColor White
    Write-Host ""
    Write-Host "ตัวอย่างการใช้งาน:" -ForegroundColor Cyan
    Write-Host "  riso ping" -ForegroundColor Gray
    Write-Host "  riso test" -ForegroundColor Gray
    Write-Host "  riso print `"D:\เอกสาร.pdf`"" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
}

$cmdLower = $Command.ToLower()

if ($cmdLower -eq "ping" -or $cmdLower -eq "test-connection") {
    Show-Header
    $isOnline = Test-RisoPing
    $isPortOpen = Test-RisoPort
    if ($isOnline -and $isPortOpen) {
        Write-Host "`n[+] เครื่องพิมพ์ RISO ORPHIS FW1230 พร้อมรับงานพิมพ์ 100%!" -ForegroundColor Green
    } else {
        Write-Host "`n[-] เครื่องพิมพ์ยังไม่พร้อม กรุณาตรวจสอบสาย LAN หรือการเชื่อมต่อ Wi-Fi" -ForegroundColor Yellow
    }
}
elseif ($cmdLower -eq "check" -or $cmdLower -eq "status") {
    Show-Header
    $isOnline = Test-RisoPing
    $isPortOpen = Test-RisoPort
    Write-Host "`n[*] ข้อมูลเครื่องพิมพ์ในระบบ Windows:" -ForegroundColor Cyan
    $prt = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($prt) {
        Write-Host "    ชื่อเครื่องพิมพ์: $($prt.Name)" -ForegroundColor White
        Write-Host "    สถานะ (Spooler): $($prt.PrinterStatus)" -ForegroundColor White
        Write-Host "    พอร์ตที่ใช้:     $($prt.PortName)" -ForegroundColor White
        Write-Host "    งานที่ค้างในคิว: $($prt.JobCount) งาน" -ForegroundColor White
    } else {
        Write-Host "    [!] ยังไม่พบเครื่องพิมพ์ '$PrinterName' ติดตั้งอยู่ในระบบนี้" -ForegroundColor Yellow
        Write-Host "    (สามารถรัน 'riso install' เพื่อติดตั้งได้ทันที)" -ForegroundColor Gray
    }
}
elseif ($cmdLower -eq "test" -or $cmdLower -eq "testpage") {
    Show-Header
    Write-Host "[*] กำลังตรวจสอบสถานะเครื่องพิมพ์ก่อนส่งงาน..." -ForegroundColor Cyan
    if (-not (Test-RisoPing)) {
        Write-Host "`n[!] ข้อผิดพลาด: ไม่สามารถ Ping $PrinterIP ได้ กรุณาเชื่อมต่อเครือข่ายก่อนสั่งพิมพ์" -ForegroundColor Red
        exit 1
    }
    
    $prt = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if (-not $prt) {
        Write-Host "[!] ยังไม่ได้ติดตั้งไดรเวอร์เครื่องพิมพ์ในเครื่องนี้ กำลังสั่งติดตั้งอัตโนมัติ..." -ForegroundColor Yellow
        & "$PSScriptRoot\install.ps1" -Silent
    }

    Write-Host "[*] สั่งพิมพ์หน้าทดสอบ (Windows Printer Test Page)..." -ForegroundColor Cyan
    rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
    Write-Host "[+] ส่งคำสั่งพิมพ์หน้าทดสอบไปยัง $PrinterName เรียบร้อยแล้ว!" -ForegroundColor Green
}
elseif ($cmdLower -eq "print" -or $cmdLower -eq "send") {
    Show-Header
    if (-not $Target) {
        Write-Host "[!] กรุณาระบุไฟล์ที่ต้องการสั่งพิมพ์ เช่น: riso print `"C:\docs\test.pdf`"" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $Target)) {
        Write-Host "[!] ไม่พบไฟล์: $Target" -ForegroundColor Red
        exit 1
    }

    $fullPath = (Resolve-Path $Target).Path
    Write-Host "[*] ไฟล์ที่ต้องการพิมพ์: $fullPath" -ForegroundColor White

    if (-not (Test-RisoPing)) {
        Write-Host "`n[!] ข้อผิดพลาด: ไม่สามารถติดต่อ $PrinterIP ได้ กรุณาเชื่อมต่อ Wi-Fi หรือ LAN โรงเรียน" -ForegroundColor Red
        exit 1
    }

    $prt = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if (-not $prt) {
        Write-Host "[*] ติดตั้งไดรเวอร์อัตโนมัติก่อนพิมพ์..." -ForegroundColor Yellow
        & "$PSScriptRoot\install.ps1" -Silent
    }

    $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
    Write-Host "[*] กำลังส่งคำสั่งพิมพ์ไปยัง '$PrinterName'..." -ForegroundColor Cyan

    try {
        if ($ext -in ".txt", ".log", ".csv") {
            Get-Content $fullPath | Out-Printer -Name $PrinterName
        } else {
            Start-Process -FilePath $fullPath -Verb PrintTo -ArgumentList "`"$PrinterName`"" -WindowStyle Hidden -ErrorAction Stop
        }
        Write-Host "[+] สั่งพิมพ์สำเร็จ! งานพิมพ์ถูกส่งไปยัง $PrinterName เรียบร้อยแล้ว" -ForegroundColor Green
    } catch {
        Write-Host "[-] เกิดข้อผิดพลาดในการสั่งพิมพ์: $_" -ForegroundColor Red
    }
}
elseif ($cmdLower -eq "queue" -or $cmdLower -eq "jobs") {
    Show-Header
    $jobs = Get-PrintJob -PrinterName $PrinterName -ErrorAction SilentlyContinue
    if ($jobs) {
        Write-Host "`n[*] คิวงานพิมพ์ปัจจุบัน ($($jobs.Count) รายการ):" -ForegroundColor Cyan
        $jobs | Select-Object Id, DocumentName, UserName, JobStatus, TotalPages, Size | Format-Table -AutoSize
    } else {
        Write-Host "`n[+] ไม่มีงานพิมพ์ค้างในคิว (คิวว่างพร้อมพิมพ์)" -ForegroundColor Green
    }
}
elseif ($cmdLower -eq "clear" -or $cmdLower -eq "cancel") {
    Show-Header
    $jobs = Get-PrintJob -PrinterName $PrinterName -ErrorAction SilentlyContinue
    if ($jobs) {
        Write-Host "[*] กำลังยกเลิกงานพิมพ์ทั้งหมด..." -ForegroundColor Yellow
        $jobs | Remove-PrintJob
        Write-Host "[+] ลบคิวงานพิมพ์ทั้งหมดเรียบร้อย" -ForegroundColor Green
    } else {
        Write-Host "[+] ไม่มีคิวงานพิมพ์ค้างอยู่" -ForegroundColor Green
    }
}
elseif ($cmdLower -eq "default" -or $cmdLower -eq "setdefault") {
    Show-Header
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($PrinterName)
    Write-Host "[+] ตั้งค่า '$PrinterName' เป็นเครื่องพิมพ์เริ่มต้น (Default) เรียบร้อยแล้ว" -ForegroundColor Green
}
elseif ($cmdLower -eq "restart" -or $cmdLower -eq "spooler") {
    Show-Header
    Write-Host "[*] กำลังเริ่มบริการ Print Spooler ใหม่..." -ForegroundColor Yellow
    Restart-Service -Name Spooler -Force
    Write-Host "[+] Print Spooler รีสตาร์ทเรียบร้อยแล้ว" -ForegroundColor Green
}
elseif ($cmdLower -eq "install") {
    & "$PSScriptRoot\install.ps1" -Silent -SetDefault
}
else {
    Show-Help
}

