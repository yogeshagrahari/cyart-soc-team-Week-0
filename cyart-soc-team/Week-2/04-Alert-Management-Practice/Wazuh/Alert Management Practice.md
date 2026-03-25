# 🧪 Lab 01 — Alert Management Practice

## Lab Overview
**Duration:** 2–3 hours  
**Tools:** Google Sheets, Wazuh, TheHive  
**Difficulty:** Beginner

---

## Prerequisites
- Wazuh OVA installed and running
- TheHive instance accessible (local or TheHive.io)
- Google account for Sheets

---

## Task 1: Alert Classification System (Google Sheets)

### Step 1: Create the spreadsheet
```
1. Open Google Sheets → Create new sheet
2. Name it: "SOC-Alert-Tracker"
3. Create headers in Row 1:
```

| Column | Header | Description |
|--------|--------|-------------|
| A | Alert ID | Unique identifier (001, 002...) |
| B | Timestamp | UTC datetime of detection |
| C | Alert Type | Malware / Phishing / Brute Force etc. |
| D | Source IP | Attacker source IP |
| E | Destination | Targeted system/IP |
| F | CVSS Score | Numerical CVSS score |
| G | Priority | Critical/High/Medium/Low |
| H | MITRE Tactic | TA00XX |
| I | MITRE Technique | TXXXX |
| J | Status | Open/Investigating/Closed |
| K | Analyst | Assigned analyst name |
| L | Notes | Additional context |

### Step 2: Color-code priority column
```
Format → Conditional formatting:
- "Critical" → Red (#FF0000)
- "High"     → Orange (#FF6600)
- "Medium"   → Yellow (#FFCC00)
- "Low"      → Green (#00CC00)
```

### Step 3: Enter mock alerts

```
| 001 | 2026-03-24 09:00 UTC | Log4Shell Exploit    | 185.220.101.45 | 10.0.0.5 | 10.0 | Critical | TA0001 | T1190  | Open | Analyst-1 | CVE-2021-44228 |
| 002 | 2026-03-24 09:15 UTC | Phishing Email       | external       | user@co  | 6.5  | Medium   | TA0001 | T1566  | Open | Analyst-1 | |
| 003 | 2026-03-24 09:30 UTC | Brute Force SSH      | 192.168.1.100  | 10.0.0.3 | 5.3  | Medium   | TA0006 | T1110  | Open | Analyst-2 | |
| 004 | 2026-03-24 09:45 UTC | Port Scan (Nmap)     | 192.168.1.200  | network  | 2.1  | Low      | TA0043 | T1046  | Open | Analyst-2 | |
| 005 | 2026-03-24 10:00 UTC | Ransomware Detected  | internal       | 10.0.0.8 | 9.8  | Critical | TA0040 | T1486  | Open | Analyst-1 | ISOLATE IMMEDIATELY |
```

---

## Task 2: CVSS Scoring in Google Sheets

### Step 1: Create a CVSS scoring tab
```
1. Add a new tab: "CVSS-Scoring"
2. Create this layout:
```

**CVSS Scoring Worksheet:**
```
| Metric              | Value  | Score Weight |
|---------------------|--------|--------------|
| Attack Vector       | Network| 0.85         |
| Attack Complexity   | Low    | 0.77         |
| Privileges Required | None   | 0.85         |
| User Interaction    | None   | 0.85         |
| Scope               | Changed| —            |
| Confidentiality     | High   | 0.56         |
| Integrity           | High   | 0.56         |
| Availability        | High   | 0.56         |
|                     |        |              |
| CALCULATED SCORE    |        | =10.0        |
| SEVERITY            |        | Critical     |
```

---

## Task 3: Wazuh Dashboard Setup

### Step 1: Access Wazuh
```bash
# Default Wazuh Web UI:
https://<wazuh-manager-ip>

# Default credentials:
Username: admin
Password: admin (change immediately!)

# API access:
curl -k -u admin:admin https://localhost:55000/
```

### Step 2: Configure alert rules
```xml
<!-- Add custom rule in /var/ossec/etc/rules/local_rules.xml -->
<group name="soc_training,">
  
  <!-- Rule: Detect multiple failed SSH logins -->
  <rule id="100001" level="10" frequency="5" timeframe="120">
    <if_matched_sid>5760</if_matched_sid>
    <description>Multiple SSH authentication failures - possible brute force</description>
    <group>authentication_failures,</group>
    <mitre>
      <id>T1110</id>
    </mitre>
  </rule>
  
  <!-- Rule: Detect nmap scan -->
  <rule id="100002" level="6">
    <if_sid>1002</if_sid>
    <match>nmap</match>
    <description>Possible Nmap scan detected in logs</description>
    <mitre>
      <id>T1046</id>
    </mitre>
  </rule>

</group>
```

### Step 3: Create dashboard visualization
```
1. Go to: Wazuh → Overview → Security Events
2. Click "Dashboard" → "Create new dashboard"
3. Add visualizations:
   - Pie chart: Alert level distribution (Critical/High/Med/Low)
   - Bar chart: Top 10 source IPs
   - Line chart: Alerts over time (last 24h)
   - Table: Recent critical alerts
4. Save as: "SOC Training Dashboard"
```

### Step 4: Filter for high-priority alerts
```
# In Wazuh Discover search bar:
rule.level: [9 TO 15]

# Filter by MITRE technique:
rule.mitre.technique: "T1110"

# Filter by source IP:
data.srcip: "192.168.1.100"
```

---

## Task 4: Create Incident Ticket in TheHive

### Step 1: Access TheHive
```
URL: http://<thehive-ip>:9000
Default login: admin@thehive.local / secret
```

### Step 2: Create a new case
```
1. Click "New Case" button
2. Fill in fields:
```

**Case Details:**
```yaml
Title:       "[Critical] Ransomware Detected on SERVER-X"
Date:        2026-03-24 10:00 UTC
Severity:    Critical (4)
TLP:         AMBER
PAP:         AMBER
Tags:        ["ransomware", "mitre:T1486", "endpoint", "critical"]

Description: |
  Ransomware activity detected on SERVER-X (10.0.0.8).
  
  INDICATORS OF COMPROMISE:
  - File: crypto_locker.exe
  - Hash: SHA256:a1b2c3d4e5f6...
  - Source IP: 192.168.1.50 → C2: 185.220.101.45
  - Registry key: HKCU\Software\Microsoft\Windows\CurrentVersion\Run\CryptoLocker
  
  AFFECTED SYSTEM:
  - Hostname: SERVER-X
  - IP: 10.0.0.8
  - OS: Windows Server 2019
  - Role: File Server (Production)
  
  ACTIONS TAKEN:
  - System isolated from network at 10:05 UTC
  - Memory dump preserved
  - Disk image in progress
```

### Step 3: Add observables (IOCs)
```
In the case, click "Observables" → "Add observable":

1. Type: ip        Value: 185.220.101.45    Tags: malicious, c2
2. Type: hash      Value: a1b2c3d4e5f6...   Tags: ransomware
3. Type: filename  Value: crypto_locker.exe  Tags: ransomware
4. Type: domain    Value: c2server.evil.xyz  Tags: c2, malicious
```

---

## Task 5: Escalation Email Practice

Write a 100-word escalation email to Tier 2:

```
Subject: [ESCALATION][CRITICAL] INC-2026-001 — Ransomware on SERVER-X

Hi Tier 2 Team,

Escalating Critical incident INC-2026-001 for immediate action.

SUMMARY:
- Type: Ransomware (crypto_locker.exe)
- System: SERVER-X (10.0.0.8) — Production File Server  
- Detected: 2026-03-24 10:00 UTC
- C2 IP: 185.220.101.45

ACTIONS TAKEN:
✓ Endpoint isolated at 10:05 UTC
✓ Memory dump preserved (SHA256 documented)
✓ System owner notified
✓ TheHive case created: INC-2026-001

REQUIRED: Full disk forensics and IR team engagement.

[Your Name], SOC Tier 1 Analyst
```

---

## Lab Completion Checklist

- [ ] Google Sheet alert tracker created with 5+ mock alerts
- [ ] CVSS scoring calculated for each alert
- [ ] Wazuh dashboard created with priority distribution chart
- [ ] TheHive case created with full IOC list
- [ ] Escalation email drafted
- [ ] All screenshots saved to `assets/screenshots/lab01/`

---

