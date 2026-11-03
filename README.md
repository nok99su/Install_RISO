# RISO ORPHIS FW1230 - 1-Click Auto Installer & CLI Controller

ชุดสคริปต์สำหรับติดตั้งไดรเวอร์และกู้คืนการตั้งค่าเครื่องพิมพ์ **RISO ORPHIS FW1230** อัตโนมัติ (1-Click Automated Installer) พร้อมเครื่องมือควบคุมและสั่งพิมพ์ผ่าน Command Line (CLI) ออกแบบมาสำหรับระบบเครือข่ายโรงเรียนเซนต์แมรี่ (St. Mary School Campus Network)

---

## 📌 คุณสมบัติหลัก (Key Features)

1. **1-Click Auto Installer:**
   - ติดตั้งไดรเวอร์แท้ 64-bit (`RISODRV.INF`) เข้าสู่ Windows DriverStore และ Spooler อัตโนมัติ
   - สร้างพอร์ต Standard TCP/IP (`RISO_172.16.40.194` พอร์ต 9100 แบบ RAW)
   - โคลนนิ่งค่าการตั้งค่าแม่แบบ (A4, 2-Sided Duplex พิมพ์ 2 หน้าอัตโนมัติ, การเลือกถาดกระดาษ, โหมดขาวดำ Monochrome) ให้ตรงตามเครื่องต้นทาง 100% ผ่าน `riso_settings.dat`
   - มีระบบขอสิทธิ์ Administrator (UAC Prompt) อัตโนมัติเมื่อดับเบิ้ลคลิก
   - รองรับการเปิดใช้งานโดยตรงจาก Network Shared Folder (`\\SERVER\Share`) ผ่าน `pushd`

2. **Command Line Controller (`riso`):**
   - ตรวจสอบสถานะการเชื่อมต่อเครือข่ายและพอร์ต 9100 ของ RISO
   - สั่งพิมพ์หน้าทดสอบ (Windows Printer Test Page) ได้ทันที
   - สั่งพิมพ์ไฟล์เอกสาร (PDF, Word, Text, รูปภาพ) ออกเครื่องพิมพ์โดยตรงผ่าน CLI
   - ตรวจสอบและยกเลิกคิวงานพิมพ์ที่ค้างอยู่ (Queue Management)

---

## 📁 โครงสร้างไฟล์ในโครงการ

```text
Install_RISO/
├── Install_RISO.bat       # ดับเบิ้ลคลิกเพื่อติดตั้งไดรเวอร์และตั้งค่าอัตโนมัติ
├── riso.bat               # คำสั่ง CLI สำหรับสั่งการเครื่องพิมพ์
├── riso.ps1               # สคริปต์ PowerShell ควบคุม CLI
├── install.ps1            # สคริปต์หลักสำหรับติดตั้งไดรเวอร์และ Restore ค่าคอนฟิก
├── Uninstall_RISO.bat     # ดับเบิ้ลคลิกเพื่อถอนการติดตั้งเครื่องพิมพ์
├── uninstall.ps1          # สคริปต์ถอนการติดตั้ง
├── riso_settings.dat      # ไฟล์ Backup ค่า DevMode และการตั้งค่าของ RISO
├── README.md              # คู่มือการใช้งาน (Markdown)
├── README.txt             # คู่มือการใช้งาน (Text)
└── Driver/                # โฟลเดอร์ไดรเวอร์แท้ RISO 64-bit WHQL
```

---

## 🚀 วิธีใช้งาน

### 1. ติดตั้งแบบง่าย (Double-Click)
1. ดับเบิ้ลคลิกที่ไฟล์ **`Install_RISO.bat`**
2. เมื่อมีหน้าต่างแจ้งเตือนสิทธิ์ (UAC) ให้กด **"Yes"** (ใช่)
3. ระบบจะทดสอบการเชื่อมต่อ ติดตั้งไดรเวอร์ สร้างพอร์ต และนำเข้าการตั้งค่าให้โดยอัตโนมัติ

---

### 2. สั่งการผ่าน Command Line (`riso`)

เปิด Command Prompt หรือ PowerShell ในโฟลเดอร์นี้ แล้วเรียกใช้คำสั่ง:

| คำสั่ง | คำอธิบาย |
| :--- | :--- |
| `riso ping` | ทดสอบ Ping ไปยัง `172.16.40.194` และตรวจเช็ค TCP Port 9100 |
| `riso check` | ดูสถานะเครื่องพิมพ์ใน Windows และจำนวนงานที่ค้างในคิว |
| `riso test` | สั่งพิมพ์หน้าทดสอบ (Windows Test Page) ไปยัง RISO ทันที |
| `riso print "D:\doc.pdf"` | สั่งพิมพ์ไฟล์ PDF, Word, รูปภาพ หรือ Text File ออก RISO ทันที |
| `riso queue` | ดูรายการเอกสารที่ค้างรอพิมพ์ในคิว |
| `riso clear` | ยกเลิกและลบคิวงานพิมพ์ที่ค้างอยู่ทั้งหมด |
| `riso default` | ตั้งค่า RISO เป็นเครื่องพิมพ์เริ่มต้น (Default Printer) |
| `riso restart` | รีสตาร์ทบริการ Print Spooler เมื่อมีปัญหาคิวพิมพ์ค้าง |
| `riso install` | สั่งติดตั้งไดรเวอร์และตั้งค่าอัตโนมัติ (โหมดเงียบ / Silent) |

---

## ⚙️ ข้อมูลเชิงเทคนิค (Network Specification)

* **Printer Model:** RISO ORPHIS FW1230
* **Printer IP Address:** `172.16.40.194`
* **Port Protocol:** RAW (Port 9100)
* **Print Processor:** `RC40DPP`
* **Driver Architecture:** Windows 64-bit (x64) Type 3
* **Target Network:** St. Mary School Campus Network Core System
