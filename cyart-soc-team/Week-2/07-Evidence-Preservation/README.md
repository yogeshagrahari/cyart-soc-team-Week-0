# 07 — Evidence Preservation

> **Tools:** Velociraptor · FTK Imager  
> **Goal:** Collect volatile and non-volatile forensic evidence, hash all artifacts, and maintain chain of custody.

---

##  Theory: Order of Volatility

```
Collect evidence in order of most volatile → least volatile:

```

---

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

# Follow the interactive prompts:
#   Deployment Type: Self Signed SSL
#   Public DNS: localhost (or your server IP)
#   GUI Port: 8889
#   Datastore: /opt/velociraptor/

# Step 3: Start Velociraptor server
velociraptor --config server.config.yaml frontend -v &

# Step 4: Create admin user
velociraptor --config server.config.yaml user add admin --role=administrator
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

### Velociraptor Dashboard Overview

```

```

---

### VQL Queries for Forensic Collection

#### Collect Network Connections (Volatile Data)

```sql
-- Run in Velociraptor Notebook or Hunt
-- Collect all active network connections
SELECT * FROM netstat()
WHERE Status = 'ESTABLISHED' OR Status = 'LISTEN'
ORDER BY Pid

-- Expected output:
-- Pid  | Laddr            | Raddr            | Status      | Process
-- 1234 | 0.0.0.0:22       | 192.168.1.100:56123 | ESTABLISHED | sshd
-- 5678 | 0.0.0.0:80       | 0.0.0.0:0        | LISTEN      | nginx
```


**Save output:**
```bash
# Export from CLI
velociraptor --config server.config.yaml query \
  "SELECT * FROM netstat()" > /evidence/netstat_$(date +%Y%m%d_%H%M%S).csv

# Hash the file
sha256sum /evidence/netstat_*.csv | tee /evidence/netstat.sha256
```

#### Collect Running Processes

```sql
-- List all running processes with parent info
SELECT Pid, Ppid, Name, Exe, CommandLine, CreateTime
FROM pslist()
ORDER BY CreateTime DESC
```

#### Collect Memory Dump via Artifact

```sql
-- Collect full memory dump (Windows)
SELECT * FROM Artifact.Windows.Memory.Acquisition(
    destination="C:\\forensics\\memory_dump.raw"
)
```

```bash
# After collection, hash the dump
sha256sum /forensics/memory_dump.raw
# Output: a3f7d12e4b9c0e5f8a1d3c7e9b2... memory_dump.raw

# Alternative using winpmem (on Windows)
winpmem_mini_x64_rc2.exe memory_dump.raw
```

#### Collect Filesystem Timeline

```sql
-- List recently modified files (last 2 hours)
SELECT FullPath, Mtime, Atime, Ctime, Size, IsDir
FROM glob(globs="C:\\Users\\**\\*")
WHERE Mtime > now() - 7200
ORDER BY Mtime DESC
```

#### Collect Prefetch Files (Windows execution evidence)

```sql
-- Prefetch shows what executed and when
SELECT * FROM Artifact.Windows.Forensics.Prefetch()
ORDER BY LastRunTime DESC
LIMIT 50
```

#### Collect Windows Event Logs

```sql
-- Security events: logins
SELECT System.TimeCreated.SystemTime AS Time,
       System.EventID.Value AS EventID,
       EventData.SubjectUserName AS User,
       EventData.IpAddress AS IP
FROM parse_evtx(filename="C:\\Windows\\System32\\winevt\\Logs\\Security.evtx")
WHERE System.EventID.Value = 4625  -- Failed logins
ORDER BY Time DESC
LIMIT 100
```

---

##  Section 2: FTK Imager

### What is FTK Imager?

FTK Imager is a forensic imaging tool that creates exact bit-for-bit copies of storage devices and memory for evidence analysis.

**Download:** https://www.exterro.com/ftk-imager (Free)

### Memory Dump with FTK Imager

**Step 1:** Launch FTK Imager as **Administrator**

**Step 2:** Go to **File → Capture Memory**

**Step 3:** Click **Capture Memory** and wait for completion.

**Step 4:** Hash the memory dump:

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

**Step 1:** File → Add Evidence Item → Physical Drive

##  Chain of Custody Documentation

```

         DIGITAL EVIDENCE CHAIN OF CUSTODY FORM
         CyArt Security Operations Center


Case Number:        INC-2025-001
Incident Type:      Ransomware
Collected By:       SOC Analyst-A
Collection Date:    2025-08-18
Location:           prod-db-01 (10.0.0.25) — Server Room A

──────────────────────────────────────────────────────────────────
EVIDENCE ITEMS:
──────────────────────────────────────────────────────────────────


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

──────────────────────────────────────────────────────────────────
CHAIN OF CUSTODY:
──────────────────────────────────────────────────────────────────

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

──────────────────────────────────────────────────────────────────
INTEGRITY VERIFICATION LOG:
──────────────────────────────────────────────────────────────────

Verified By:    SOC Analyst-A
Verified At:    2025-08-18 12:25 UTC
Method:         sha256sum on all files
Result:          All hashes match — evidence integrity confirmed
```

---

## 📚 Resources

- [Velociraptor Documentation](https://docs.velociraptor.app)
- [Velociraptor VQL Reference](https://docs.velociraptor.app/vql_reference/)
- [FTK Imager Guide (Exterro)](https://www.exterro.com/ftk-imager)
- [SANS DFIR Resources](https://www.sans.org/digital-forensics-incident-response/)
- [NIST Digital Forensics Guide SP 800-86](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-86.pdf)
