# 🐝 TheHive — Incident Ticketing Guide

> **Tool:** TheHive 5.x  
> **Purpose:** Security Incident Case Management, Alert Triage, Collaborative Investigation

---

## 🔧 Installation Steps

### Docker Installation (Recommended)

```bash
# Step 1: Create docker-compose.yml
mkdir thehive && cd thehive
cat > docker-compose.yml << 'EOF'
version: "3"
services:
  thehive:
    image: strangebee/thehive:5.2
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      - JVM_OPTS=-Xms512m -Xmx512m
    volumes:
      - ./thehive-data:/opt/thp/thehive/db
      - ./thehive-index:/opt/thp/thehive/index
      - ./thehive-files:/opt/thp/thehive/files
EOF

# Step 2: Start TheHive
docker-compose up -d

# Step 3: Check status
docker-compose ps
docker-compose logs thehive | tail -20
```

**Access:** `http://localhost:9000`  
**Default Admin:** `admin@thehive.local` / `secret`

---

## 🌐 TheHive Dashboard Overview

```
Screenshot Reference — TheHive Dashboard:
┌────────────────────────────────────────────────────────────────┐
│  🐝 TheHive                                  [admin ▼]  [+]  │
│  ──────────────────────────────────────────────────────────    │
│  📊 Dashboard  📋 Cases  🚨 Alerts  🔍 Observables  ⚙ Admin  │
│                                                                │
│  Recent Activity                    Statistics                 │
│  ┌───────────────────────────────┐  ┌──────────────────────┐  │
│  │ [NEW]  INC-001 Ransomware    │  │  Open Cases:    5    │  │
│  │        Aug 18 11:45          │  │  In Progress:   3    │  │
│  │ [OPEN] INC-002 Phishing      │  │  Resolved:      12   │  │
│  │        Aug 18 10:30          │  │  Alerts Today:  47   │  │
│  │ [DONE] INC-003 Port Scan     │  └──────────────────────┘  │
│  │        Aug 17 09:00          │                            │
│  └───────────────────────────────┘  TLP Distribution:        │
│                                     RED:   2  AMBER: 8       │
│                                     GREEN: 3  WHITE: 4       │
└────────────────────────────────────────────────────────────────┘
```

---

## 🎫 Creating an Incident Ticket — Step by Step

### Step 1: Navigate to Cases → New Case

```
Screenshot Reference — New Case Form:
┌────────────────────────────────────────────────────────────────┐
│  Create New Case                                    [✕]        │
│  ──────────────────────────────────────────────────────────    │
│                                                                │
│  Title:        [Critical] Ransomware Detected on Server-X      │
│                                                                │
│  Severity:     ○ Low  ○ Medium  ○ High  ● Critical            │
│                                                                │
│  TLP:          ○ WHITE  ○ GREEN  ○ AMBER  ● RED               │
│                                                                │
│  PAP:          ● WHITE  ○ GREEN  ○ AMBER  ○ RED               │
│                                                                │
│  Tags:         [ransomware] [windows] [server] [+Add]         │
│                                                                │
│  Assignee:     [SOC Analyst ▼]                                │
│                                                                │
│  Description:                                                  │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ Ransomware activity detected on production server     │    │
│  │ Server-X (10.0.0.25). File encryption in progress.   │    │
│  │ Source: Wazuh FIM Alert Rule 550                      │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                │
│              [Cancel]  [Create Case]                          │
└────────────────────────────────────────────────────────────────┘
```

### Step 2: Add Observables (IOCs)

```
Screenshot Reference — Add Observable:
┌────────────────────────────────────────────────────────────────┐
│  Add Observable                                     [✕]        │
│  ──────────────────────────────────────────────────────────    │
│                                                                │
│  Type:         [File Hash (MD5/SHA256) ▼]                     │
│                                                                │
│  Value:        a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a...   │
│                                                                │
│  Description:  crypto_locker.exe — ransomware binary          │
│                                                                │
│  Tags:         [malware] [ransomware]                         │
│                                                                │
│  ● Mark as IoC    □ Ignore for similarity                     │
│                                                                │
│              [Cancel]  [Add Observable]                       │
└────────────────────────────────────────────────────────────────┘
```

**Observable Types to Add:**
```
Type: hash          Value: sha256:a3f7d12e...    (Malware binary)
Type: ip            Value: 192.168.1.50          (Source host)
Type: ip            Value: 45.33.32.156          (Attacker C2 IP)
Type: filename      Value: crypto_locker.exe     (Malware filename)
Type: domain        Value: evil-c2.ru            (C2 domain if known)
```

### Step 3: Add Tasks

```
Tasks to Create:
  ┌─────────────────────────────────────────────────────────┐
  │ Task 1: Initial Triage              [Analyst-A]         │
  │ Task 2: Isolate Affected System     [Analyst-A]         │
  │ Task 3: Collect Evidence            [Analyst-B]         │
  │ Task 4: Threat Intelligence Check   [Analyst-A]         │
  │ Task 5: Eradication                 [Tier 2]            │
  │ Task 6: Write Post-Mortem Report    [SOC Lead]          │
  └─────────────────────────────────────────────────────────┘
```

### Step 4: Add a Case Timeline Log

```
Timeline Entry:
  Date:     2025-08-18 11:43 UTC
  Message:  Wazuh FIM Alert triggered — file crypto_locker.exe
            created in C:\Users\Admin\AppData\Local\Temp\
            Rule: 550 | Level: 12 (High)

  Date:     2025-08-18 11:45 UTC
  Message:  Host Server-X isolated from network via iptables

  Date:     2025-08-18 12:00 UTC
  Message:  Memory dump collected - SHA256: a3f7d12e...
```

---

## 📋 Complete Incident Ticket — Filled Example

```
Case ID:        CS-2025-001
Title:          [P1-Critical] Ransomware Detected on Server-X
Severity:       Critical
Status:         In Progress
TLP:            RED (Internal only)
Created:        2025-08-18 11:45 UTC
Assignee:       SOC Analyst-A

DESCRIPTION:
  Ransomware activity (crypto_locker.exe) detected on production
  server Server-X (hostname: prod-db-01, IP: 10.0.0.25).
  Wazuh File Integrity Monitoring (FIM) triggered on suspicious
  executable in temp directory. Rapid file modification events
  suggest active encryption.

INDICATORS OF COMPROMISE:
  Type      Value                                     IOC?
  ────────────────────────────────────────────────────────
  hash      sha256:a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d  YES
  filename  crypto_locker.exe                         YES
  ip        192.168.1.50 (Affected host)              YES
  ip        45.33.32.156 (Suspected attacker C2)      YES

TASKS:
  [DONE]  Isolate host from network      Analyst-A  Aug 18 11:45
  [DONE]  Collect memory dump            Analyst-A  Aug 18 12:00
  [OPEN]  Analyze malware sample         Analyst-B  -
  [OPEN]  Check lateral movement         Tier 2     -
  [OPEN]  Restore from backup            IT Ops     -
```

---

## ⚡ TheHive API — Automated Ticket Creation

```bash
# Create TheHive case via API (curl)
curl -X POST "http://localhost:9000/api/v1/case" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "[P1-Critical] Ransomware Detected on Server-X",
    "description": "Ransomware activity detected via Wazuh FIM",
    "severity": 3,
    "tlp": 3,
    "tags": ["ransomware", "critical", "wazuh"],
    "tasks": [
      {"title": "Isolate host"},
      {"title": "Collect evidence"},
      {"title": "Threat intel check"}
    ]
  }'
```

---

## 📚 Resources

- [TheHive Documentation](https://docs.thehive-project.org)
- [TheHive API Reference](https://docs.thehive-project.org/thehive/api/case/create-case/)
- [Cortex Integration (IOC analysis)](https://github.com/TheHive-Project/Cortex)
