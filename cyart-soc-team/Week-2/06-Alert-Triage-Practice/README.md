# 🔍 06 — Alert Triage Practice

> **Tools:** Wazuh · VirusTotal · AlienVault OTX  
> **Goal:** Simulate alert triage, validate IOCs with threat intelligence, distinguish true positives from false positives.

---

## 📋 Alert Triage Workflow

```
INCOMING ALERT
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Read the Alert                                      │
│   → What is the rule? What triggered it?                    │
│   → What is the source IP / hostname?                       │
│   → What is the timestamp?                                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Is this a known false positive pattern?             │
│   → YES → Mark as FP, document, and close                  │
│   → NO  → Continue to Step 3                               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Threat Intelligence Check                           │
│   → Check IP in VirusTotal / AlienVault OTX                │
│   → Check file hash in VirusTotal                          │
│   → Check domain/URL reputation                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
      MALICIOUS / SUSPICIOUS     CLEAN / UNKNOWN
              │                       │
              ▼                       ▼
       → Open TheHive Ticket    → Monitor, log, escalate
       → Assign Priority               if pattern repeats
       → Contain if P1/P2
```

---

## 🖥️ Section 1: Wazuh Triage

### Accessing Alerts in Wazuh

**Step 1:** Login to Wazuh Dashboard → `https://[wazuh-ip]`

**Step 2:** Navigate to **Security Events** → **Threat Detection**

```
Screenshot Reference — Wazuh Security Events:
┌────────────────────────────────────────────────────────────────┐
│  ☰  WAZUH → Security Events                    [admin ▼]      │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  🔍 [Search alerts...    ] [Last 24 hours ▼]  [Refresh ▼]    │
│                                                                │
│  Filters: [Agent: All ▼] [Level: All ▼] [MITRE: All ▼]       │
│                                                                │
│  ┌──────┬──────────────────┬────────────┬───────┬───────────┐ │
│  │Level │ Rule Description │ Agent Name │ Count │ Timestamp │ │
│  ├──────┼──────────────────┼────────────┼───────┼───────────┤ │
│  │ 12   │ SSH brute force  │ prod-db-01 │  547  │ 11:43     │ │
│  │ 10   │ FIM - new file   │ prod-db-01 │  203  │ 11:41     │ │
│  │  7   │ Failed sudo      │ workstation│   12  │ 11:30     │ │
│  │  5   │ Syscheck - change│ web-01     │   87  │ 10:15     │ │
│  └──────┴──────────────────┴────────────┴───────┴───────────┘ │
│                                                                │
│  [Export CSV]  [Visualize]  [Save Search]                     │
└────────────────────────────────────────────────────────────────┘
```

### Viewing a Specific Alert Detail

**Click on any alert row to expand:**

```
Alert Detail — SSH Brute Force:
┌────────────────────────────────────────────────────────────────┐
│  Alert Details                                       [✕]      │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  Rule ID:      100001                                          │
│  Level:        12                                             │
│  Description:  SSH brute force attack: 547 attempts in 60s    │
│  Agent:        prod-db-01 (10.0.0.25)                         │
│  Timestamp:    2025-08-18T11:43:00.000Z                       │
│  MITRE:        T1110 — Brute Force                            │
│                                                                │
│  Log Sample:                                                   │
│  Aug 18 11:43:00 sshd[12345]: Failed password for root        │
│  from 192.168.1.100 port 22 ssh2                              │
│                                                                │
│  Source IP:    192.168.1.100                                  │
│  Destination:  10.0.0.25:22                                   │
│                                                                │
│  [Open in TheHive]  [Add to Watchlist]  [Download Alert]      │
└────────────────────────────────────────────────────────────────┘
```

### Wazuh CLI — Searching Logs

```bash
# View all alerts for a specific IP
grep "192.168.1.100" /var/ossec/logs/alerts/alerts.log

# View alerts from the last hour with level 10+
grep "$(date +'%b %d')" /var/ossec/logs/alerts/alerts.log | grep -E "level: (1[0-9]|[2-9][0-9])"

# View all SSH failed logins
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head 20

# Count authentication failures by IP
sudo grep "authentication failure" /var/ossec/logs/alerts/alerts.log | grep -oP 'srcip=\K[0-9.]+' | sort | uniq -c | sort -rn

# Get alert stats
sudo /var/ossec/bin/ossec-reportd
```

---

## 🦠 Section 2: VirusTotal Analysis

### How to Use VirusTotal

**Website:** https://www.virustotal.com

#### Method 1: Check a File Hash

```
Step 1: Go to virustotal.com
Step 2: Click "Search" tab
Step 3: Paste your hash:
        SHA256: a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a6d8b0c2e4a6d8f0a2c4e6d
Step 4: Press Enter
```

```
Screenshot Reference — VirusTotal Hash Result:
┌────────────────────────────────────────────────────────────────┐
│  VirusTotal                               [Search...     🔍]  │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  📄 crypto_locker.exe                                          │
│  SHA256: a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0...              │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  🚨  58 / 72  security vendors flagged this file        │  │
│  │                                                         │  │
│  │  Malicious ████████████████████████████░░░░ 58          │  │
│  │  Suspicious ██░ 3                                       │  │
│  │  Undetected ░░░ 11                                      │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  Detection Names:                                              │
│  Kaspersky:    Trojan-Ransom.Win32.Locky.abc                   │
│  Sophos:       Troj/Ransom-GHI                                 │
│  Microsoft:    Ransom:Win32/CryptoLocker.A                     │
│  CrowdStrike:  malicious_confidence_100%                       │
│                                                                │
│  First Seen:   2025-08-10    Last Seen: 2025-08-18            │
│  File Type:    PE32+ executable (GUI) x86-64                  │
│  File Size:    287 KB                                          │
└────────────────────────────────────────────────────────────────┘
```

#### Method 2: Check an IP Address

```
Step 1: Click "Search" tab
Step 2: Enter IP: 45.33.32.156
Step 3: Review results
```

```
Screenshot Reference — VirusTotal IP Result:
┌────────────────────────────────────────────────────────────────┐
│  IP Address: 45.33.32.156                                      │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  ⚠️  12 / 94 security vendors flagged this IP                 │
│                                                                │
│  Country:    Russia 🇷🇺                                         │
│  ASN:        AS12389 — Rostelecom                              │
│  Owner:      Unknown threat actor                              │
│                                                                │
│  Last Analysis: 2025-08-18                                     │
│  Categories:   Malware distribution, C2 server                │
│                                                                │
│  Community Score:  -27  (Malicious)                           │
│                                                                │
│  Associated Files: 14 malware samples linked                   │
│  Relations:  Contacted by 3 malware families                  │
└────────────────────────────────────────────────────────────────┘
```

#### VirusTotal via API (Automated)

```bash
# Install requests if needed
pip3 install requests

# Query hash via API
VT_API_KEY="YOUR_API_KEY_HERE"
FILE_HASH="a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a6d8b0c2e4a6d8f0a2c4e6d"

curl -s "https://www.virustotal.com/api/v3/files/${FILE_HASH}" \
  -H "x-apikey: ${VT_API_KEY}" | python3 -m json.tool | grep -A5 "last_analysis_stats"

# Query IP address
IP="45.33.32.156"
curl -s "https://www.virustotal.com/api/v3/ip_addresses/${IP}" \
  -H "x-apikey: ${VT_API_KEY}" | python3 -m json.tool | grep -A5 "last_analysis_stats"
```

---

## 🛰️ Section 3: AlienVault OTX Analysis

### How to Use AlienVault OTX

**Website:** https://otx.alienvault.com  
**Free Registration Required**

#### Step-by-Step IOC Lookup

**Step 1:** Register at https://otx.alienvault.com

**Step 2:** Click **"Indicators"** in the top menu

**Step 3:** Search your IOC (IP, hash, domain, URL)

```
Screenshot Reference — AlienVault OTX IP Search:
┌────────────────────────────────────────────────────────────────┐
│  AlienVault OTX Open Threat Exchange                           │
│  ─────────────────────────────────────────────────────────     │
│  [Search indicators...          🔍]                            │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  🌐 IPv4: 45.33.32.156                                         │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  ⚠️  Malicious Activity Detected                               │
│                                                                │
│  Pulse Count:      14 Threat Intelligence Reports              │
│  Activities:       Scanning, C2, Malware Distribution          │
│  Countries Targeted: US, UK, DE, FR, IN                        │
│  First Seen:       2025-01-12                                  │
│  Last Seen:        2025-08-17                                  │
│                                                                │
│  Associated Malware:                                           │
│  • CryptoLocker Ransomware (High Confidence)                   │
│  • Emotet (Medium Confidence)                                  │
│                                                                │
│  Threat Actors:   Lazarus Group (Low Confidence)               │
│                                                                │
│  Related Pulses:                                               │
│  [Ransomware Campaign Aug 2025]  [Eastern European C2 IPs]    │
└────────────────────────────────────────────────────────────────┘
```

#### OTX via API (Automated)

```bash
# Install OTX SDK
pip3 install OTXv2

# Python script: check IP in OTX
cat > otx_check.py << 'EOF'
from OTXv2 import OTXv2, IndicatorTypes

API_KEY = "YOUR_OTX_API_KEY"
otx = OTXv2(API_KEY)

# Check IP reputation
ip = "45.33.32.156"
alerts = otx.get_indicator_details_full(IndicatorTypes.IPv4, ip)
print(f"\nIP: {ip}")
print(f"Pulse Count: {len(alerts['general']['pulse_info']['pulses'])}")
print(f"Reputation: {alerts['general'].get('reputation', 'N/A')}")

# Check file hash
file_hash = "a3f7d12e4b9c0e5f8a1d3c7e9b2f4a6d8c0e2f4a6d8f0a2c4e6d"
hash_alerts = otx.get_indicator_details_full(IndicatorTypes.FILE_HASH_SHA256, file_hash)
print(f"\nHash: {file_hash[:16]}...")
print(f"Pulse Count: {len(hash_alerts['general']['pulse_info']['pulses'])}")
EOF

python3 otx_check.py
```

---

## 📊 Triage Results Documentation

### Triage Log Template

```
ALERT TRIAGE LOG
════════════════════════════════════════════════════════════════

Alert ID:       ALT-004
Date/Time:      2025-08-18 11:43 UTC
Alert Source:   Wazuh (Rule 100001)
Description:    Brute-force SSH Attempts — 547 in 60 seconds
Source IP:      192.168.1.100
Target:         prod-db-01:22 (10.0.0.25)
Analyst:        Analyst-A

TRIAGE STEPS:
─────────────

Step 1 — False Positive Check:
  Is 192.168.1.100 a known scanner? NO
  Is this a scheduled maintenance window? NO
  → Result: Likely TRUE POSITIVE

Step 2 — VirusTotal IP Check:
  IP: 192.168.1.100
  VT Score: 8/94 vendors flagged
  Categories: SSH Scanner, Brute Force
  → Result: SUSPICIOUS / MALICIOUS

Step 3 — AlienVault OTX Check:
  IP: 192.168.1.100
  OTX Pulses: 3 threat reports
  Associated with: "SSH Brute Force Campaign 2025"
  → Result: CONFIRMED MALICIOUS

Step 4 — Priority Assignment:
  Target Asset Tier: Tier 2 (SSH server)
  Active exploitation: YES (ongoing brute force)
  CVSS (estimated): 7.5
  Priority: P2-HIGH

Step 5 — Action Taken:
  [x] Opened TheHive ticket CS-2025-003
  [x] Source IP blocked via iptables
  [x] Notified Tier 2 analyst

Threat Intel Summary (50 words):
  IP 192.168.1.100 confirmed malicious per AlienVault OTX (3 pulse
  reports) and VirusTotal (8/94 detections). IP associated with SSH
  brute-force campaign active since July 2025. Target prod-db-01 SSH
  service had 547 failed login attempts in 60 seconds. IP has been
  blocked and incident escalated to Tier 2.
```
