# 07 — Evidence Preservation

> **Tools:** Velociraptor · FTK Imager  
> **Goal:** Collect volatile and non-volatile forensic evidence, hash all artifacts, and maintain chain of custody.
> **Difficulty:** Intermediate
> **Duration:** 2–3 hours 

---

## Prerequisites
- Windows test VM (Windows 10/11 or Server)
- Velociraptor server deployed (or standalone executable)
- FTK Imager installed (free from AccessData)
- Linux system with sha256sum

---
---

##  Theory: Order of Volatility

```
Collect evidence in order of most volatile → least volatile:

```

##  Section 1: Velociraptor

### What is Velociraptor?

Velociraptor is a digital forensics and incident response (DFIR) tool that lets you collect forensic artifacts from endpoints using a query language called **VQL (Velociraptor Query Language)**.

### Installation

#### Server Installation (Ubuntu)

```bash
# Step 1: Download Velociraptor
wget https://github.com/Velocidex/velociraptor/releases/download/v0.7.0/velociraptor-v0.7.0-linux-amd64
chmod +x velociraptor-v0.7.0-linux-amd64
sudo mv velociraptor-v0.7.0-linux-amd64 /usr/local/bin/velociraptor

# Step 2: Generate server configuration
velociraptor config generate -i

# Answer prompts:
# Deployment type: Self-signed SSL
# Which IP/domain: <your-server-ip>
# Admin username: admin
# Admin password: <strong-password>

# Follow the interactive prompts:
#   Deployment Type: Self Signed SSL
#   Public DNS: localhost (or your server IP)
#   GUI Port: 8889
#   Datastore: /opt/velociraptor/

# Step 3: Start Velociraptor server
velociraptor --config server.config.yaml frontend -v
# Access at: https://<server-ip>:8889
# Step 4: Create admin user
velociraptor --config server.config.yaml user add admin --role=administrator

Deploy Velociraptor Agent on Windows VM
```powershell
# On Windows test VM (PowerShell as Administrator):

# Download the Windows agent MSI
# (Get URL from Velociraptor UI → Add clients → Windows)

# Install agent silently
msiexec /i velociraptor-agent.msi /quiet

# Verify agent is running
Get-Service | Where-Object {$_.Name -like "*velociraptor*"}

# Expected output:
# velociraptor   Running   Velociraptor
```


```

**Access GUI:** `https://localhost:8889`

#### Agent Deployment on Windows Target

```powershell
# On Windows target VM — Run as Administrator:
# Step 1: Download agent MSI from Velociraptor server
Invoke-WebRequest -Uri "https://[server-ip]:8889/downloads/agent.msi" -OutFile "C:\agent.msi"

# Step 2: Install agent
msiexec /i C:\agent.msi /quiet

# Step 3: Verify agent is running
Get-Service -Name Velociraptor
```

---


## Volatile Data Collection

### Step 2a: Collect Network Connections
```sql
-- In Velociraptor UI → Collect Artifact → Windows.Network.Netstat
-- Or run this VQL in notebook:

SELECT Pid, Name, Status, LocalAddress, LocalPort, 
       RemoteAddress, RemotePort
FROM netstat()
WHERE Status = 'ESTABLISHED'
ORDER BY Name
```

**Expected output (save to CSV):**
```
| Pid  | Name          | Status      | LocalAddress   | LocalPort | RemoteAddress  | RemotePort |
|------|---------------|-------------|----------------|-----------|----------------|------------|
| 4856 | chrome.exe    | ESTABLISHED | 192.168.1.101  | 52341     | 142.250.80.46  | 443        |
| 1234 | svchost.exe   | ESTABLISHED | 192.168.1.101  | 49152     | 52.86.100.12   | 443        |
| 8892 | UNKNOWN.exe   | ESTABLISHED | 192.168.1.101  | 55431     | 185.220.101.45 | 4444       |
```

```sql
-- Save results to CSV:
-- In Velociraptor: Download results → Export CSV
-- Filename: netstat_SERVER-X_2026-03-24.csv
```

### Step 2b: Collect Running Processes
```sql
-- VQL: Running processes with network connections
SELECT Pid, Ppid, Name, Exe, CommandLine, Username, 
       CreateTime
FROM pslist()
ORDER BY CreateTime DESC
LIMIT 100
```

### Step 2c: Collect Logged-on Users
```sql
-- VQL: Currently logged-on users
SELECT Name, Type, Sid, LogonTime
FROM Artifact.Windows.Sys.LoggedInUsers()
```

## Task 3: Memory Acquisition

### Step 3a: Via Velociraptor (Recommended)
```sql
-- In Velociraptor UI → Collect Artifact:
-- Search for: Windows.Memory.Acquisition

-- Or run via Velociraptor GUI:
-- 1. Select your Windows client
-- 2. Click "Collect" → "Add new collection"
-- 3. Search: Windows.Memory.Acquisition
-- 4. Click "Launch"
-- 5. Wait for collection to complete (~5-15 minutes)
-- 6. Download the memory image from "Results" tab
```

### Step 3b: Via WinPmem (Manual Method)
```powershell
# Download WinPmem from GitHub:
# https://github.com/Velocidex/WinPmem/releases

# Run as Administrator in PowerShell:
cd C:\Tools\winpmem

# Acquire memory to local file:
.\winpmem_mini_x64_rc2.exe C:\Evidence\memory_dump_SERVER-X.raw

# Expected output:
# WinPmem 4.0.rc1.
# Acquiring Memory...
# Progress: [########################################] 100%
# Total bytes: 8589934592 (8.0 GB)
# Completed in 120 seconds.
```

Evidence Hashing & Chain of Custody

### Step 4a: Hash the collected evidence
```bash
# On Linux (Wazuh/analyst workstation):

# Hash memory dump
sha256sum memory_dump_SERVER-X.raw > memory_dump_SERVER-X.raw.sha256
cat memory_dump_SERVER-X.raw.sha256
# Output: a3f2b1c9... memory_dump_SERVER-X.raw

# Hash disk image
sha256sum disk_image_SERVER-X.E01 > disk_image_SERVER-X.E01.sha256

# Hash CSV collection
sha256sum netstat_SERVER-X_2026-03-24.csv > netstat_SERVER-X_2026-03-24.csv.sha256

# Verify hash (after copying/transferring):
sha256sum -c memory_dump_SERVER-X.raw.sha256
# Output: memory_dump_SERVER-X.raw: OK
```

```powershell
# On Windows:
# Get-FileHash is the equivalent:
Get-FileHash -Path "C:\Evidence\memory_dump_SERVER-X.raw" -Algorithm SHA256

# Output:
# Algorithm  Hash                                              Path
# SHA256     A3F2B1C9...                                       C:\Evidence\memory_dump...
```

### Document Chain of Custody

```
CHAIN OF CUSTODY FORM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Incident ID:       INC-2026-001
Case Name:         Ransomware — SERVER-X
Case Number:       CASE-2026-001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVIDENCE ITEM 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evidence ID:       EVD-001
Item Type:         Memory Dump
Filename:          memory_dump_SERVER-X.raw
File Size:         8.0 GB (8,589,934,592 bytes)
SHA256 Hash:       a3f2b1c9d4e5f6789012345678901234567890123456789012345678
                   90123456 (64 chars)
MD5 Hash:          a1b2c3d4e5f6789012345678

Source System:
  Hostname:        SERVER-X
  IP Address:      10.0.0.30
  OS:              Windows Server 2019
  Role:            Production File Server

Collection:
  Collected By:    [Analyst Name]
  Method:          WinPmem 4.0.rc1
  Collection Time: 2026-03-24 10:15:00 UTC
  Storage Location: /evidence/INC-2026-001/EVD-001/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CUSTODY LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Date/Time (UTC)       | From              | To                | Purpose           | Signature |
|---|-----------------------|-------------------|-------------------|-------------------|-----------|
| 1 | 2026-03-24 10:15 UTC  | SYSTEM (live)     | SOC Analyst-1     | Initial collection| [sign]    |
| 2 | 2026-03-24 10:45 UTC  | SOC Analyst-1     | Evidence Storage  | Secured storage   | [sign]    |
| 3 | 2026-03-24 14:00 UTC  | Evidence Storage  | IR Forensics Team | Deep analysis     | [sign]    |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVIDENCE ITEM 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evidence ID:       EVD-002
Item Type:         Network Connection Export (CSV)
Filename:          netstat_SERVER-X_2026-03-24.csv
File Size:         24 KB
SHA256 Hash:       b5c6d7e8f9012345678901234567890123456789012345678901234567
                   8901234 (64 chars)
Collection Time:   2026-03-24 10:10:00 UTC
Collected By:      [Analyst Name]
Method:            Velociraptor Windows.Network.Netstat artifact
```



##  Section 2: FTK Imager

### What is FTK Imager?

FTK Imager is a forensic imaging tool that creates exact bit-for-bit copies of storage devices and memory for evidence analysis.

**Download:** https://www.exterro.com/ftk-imager (Free)

### Memory Dump with FTK Imager

**Step 1:** Launch FTK Imager as **Administrator**

**Step 2:** Go to **File → Capture Memory**
**step 3:** Select source:
   - Physical Drive → \\.\PhysicalDrive0
**Step 4:** Click **Capture Memory** and wait for completion.
**Step5:**  Add destination:
   - Image type: E01 (EnCase format, includes verification)
   - Save to: D:\Evidence\disk_image_SERVER-X.E01
   - Compression: 6
   - Fragment size: 4096 MB
   - Case number: INC-2026-001
   - Evidence number: EVD-003
   - Description: SERVER-X Production File Server Disk Image
**Step 6:** Click Start
**Step 7:** FTK Imager automatically:
   - Creates MD5 and SHA1 hashes
   - Verifies image integrity
   - Saves verification report

**Step 8:** Document the verification report:
**Step 9 :** Hash the memory dump:

```powershell
# On Windows (PowerShell)
Get-FileHash -Path "C:\forensics\memory_dump_prod-db-01_20250818.mem" -Algorithm SHA256

# Output:
# Algorithm  Hash                             Path
# SHA256     A3F7D12E4B9C0E5F8A1D3C7E9B2F4A6D C:\forensics\memory_dump...
```

```bash
# On Linux
sha256sum /forensics/memory_dump_prod-db-01_20250818.mem
```

### Disk Image Capture

**Step 1:** File - Add Evidence Item -- Physical Drive

##  Chain of Custody Documentation

```

         DIGITAL EVIDENCE CHAIN OF CUSTODY FORM
         CyArt Security Operations Center


Case Number:        INC-2025-001
Incident Type:      Ransomware
Collected By:       SOC Analyst-A
Collection Date:    2025-08-18
Location:           prod-db-01 (10.0.0.25) — Server Room A


EVIDENCE ITEMS:



Item #1
  Description:    RAM Memory Dump
  Tool Used:      FTK Imager 4.7 / Velociraptor v0.7.0
  Filename:       memory_dump_prod-db-01_20250818.mem
  File Size:      8,589,934,592 bytes (8 GB)
  SHA256 Hash:    a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a6d8
  Collected At:   2025-08-18 12:00 UTC
  Notes:          Collected before host was powered down

Item #2
  Description:    Network Connections Log (netstat)
  Tool Used:      Velociraptor VQL
  Filename:       netstat_20250818_120000.csv
  File Size:      4,521 bytes
  SHA256 Hash:    b7e2a5d8f1c4e9a2d5c8e1a4d7c0e3f6a9c2e5a8
  Collected At:   2025-08-18 11:47 UTC
  Notes:          Shows active C2 connection to 45.33.32.156

Item #3
  Description:    Malware Sample
  Tool Used:      Velociraptor file collect
  Filename:       crypto_locker.exe
  File Size:      293,888 bytes (287 KB)
  SHA256 Hash:    a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a6d8
  Collected At:   2025-08-18 12:05 UTC
  Notes:          Quarantined, do NOT execute outside sandbox

Item #4
  Description:    Windows Security Event Log
  Tool Used:      Velociraptor parse_evtx artifact
  Filename:       Security_evtx_20250818.json
  File Size:      12,847,233 bytes
  SHA256 Hash:    c9d3b6a0e4f8c2d6a0e4f8b2d6c0e4a8f2c6d0e4
  Collected At:   2025-08-18 12:10 UTC


CHAIN OF CUSTODY:


Transfer 1:
  From:     SOC Analyst-A
  To:       Evidence Storage (encrypted USB — Serial: EVD-2025-18)
  Date:     2025-08-18 12:30 UTC
  Purpose:  Secure storage pending analysis
  Signature: ___________________

Transfer 2:
  From:     Evidence Storage
  To:       Tier 2 Analyst (Forensics)
  Date:     2025-08-18 13:00 UTC
  Purpose:  Malware analysis
  Signature: ___________________


INTEGRITY VERIFICATION LOG:


Verified By:    SOC Analyst-A
Verified At:    2025-08-18 12:25 UTC
Method:         sha256sum on all files
Result:          All hashes match — evidence integrity confirmed
```
---

## Lab Completion Checklist

- [ ] Velociraptor server deployed and accessible
- [ ] Windows agent connected to Velociraptor
- [ ] netstat collection exported to CSV
- [ ] Memory dump acquired with WinPmem
- [ ] SHA256 hash computed and documented
- [ ] Chain of custody form completed
- [ ] FTK Imager disk image created (if physical lab)
- [ ] All evidence items inventoried

---
---

##  Resources

- [Velociraptor Documentation](https://docs.velociraptor.app)
- [Velociraptor VQL Reference](https://docs.velociraptor.app/vql_reference/)
- [FTK Imager Guide (Exterro)](https://www.exterro.com/ftk-imager)
- [SANS DFIR Resources](https://www.sans.org/digital-forensics-incident-response/)
- [NIST Digital Forensics Guide SP 800-86](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf)
