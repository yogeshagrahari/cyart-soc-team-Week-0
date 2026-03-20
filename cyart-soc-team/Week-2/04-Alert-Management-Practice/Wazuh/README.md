# 📡 Wazuh — Setup, Configuration & Dashboard Guide

> **Tool:** Wazuh v4.x  
> **Purpose:** SIEM, Log Analysis, File Integrity Monitoring, Alert Detection

---

## 🔧 Installation Steps

### Option A: Docker Compose (Recommended for Lab)

```bash
# Step 1: Install Docker and Docker Compose
sudo apt update && sudo apt install -y docker.io docker-compose

# Step 2: Download Wazuh Docker deployment
git clone https://github.com/wazuh/wazuh-docker.git -b v4.7.0
cd wazuh-docker/single-node

# Step 3: Generate SSL certificates
docker-compose -f generate-indexer-certs.yml run --rm generator

# Step 4: Start Wazuh stack
docker-compose up -d

# Step 5: Verify containers are running
docker-compose ps
```

**Expected Output:**
```
Name                    Command               State           Ports
─────────────────────────────────────────────────────────────────────
wazuh.manager           /init                Up      1514/tcp, 1515/tcp
wazuh.indexer           /entrypoint.sh       Up      9200/tcp
wazuh.dashboard         /entrypoint.sh       Up      443/tcp → 0.0.0.0:443
```

### Option B: OVA Virtual Appliance

```bash
# Download OVA from https://documentation.wazuh.com/current/deployment-options/virtual-machine/virtual-machine.html
# Default credentials: admin / admin (change immediately)
# Access: https://[wazuh-ip]
```

---

## 🌐 Accessing Wazuh Dashboard

**URL:** `https://localhost` or `https://[server-ip]`  
**Default Login:** `admin` / `SecretPassword`

```
Screenshot Reference — Wazuh Login Page:
┌──────────────────────────────────────────────────────┐
│                   WAZUH                               │
│              ────────────────                         │
│                                                       │
│   Username: [admin              ]                     │
│   Password: [••••••••••••••••• ]                      │
│                                                       │
│   [         Log in              ]                     │
│                                                       │
│   © 2024 Wazuh, Inc.                                  │
└──────────────────────────────────────────────────────┘
```

---

## 🖥️ Wazuh Dashboard — Key Sections

### Main Overview Dashboard

```
Screenshot Reference — Wazuh Overview:
┌────────────────────────────────────────────────────────────────┐
│  ☰  WAZUH                          [Search...]  [admin ▼]     │
│  ─────────────────────────────────────────────────────────     │
│  📊 Overview                                                   │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │Total Agents  │  │Active Agents │  │  Alerts (24h)│        │
│  │     12       │  │     10       │  │    1,247     │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                │
│  Alert Severity Distribution:                                  │
│  Critical ████░░░░░░░░ 45  (3.6%)                            │
│  High     ████████░░░░ 203 (16.3%)                           │
│  Medium   ████████████ 587 (47.1%)                           │
│  Low      ████████░░░░ 412 (33.0%)                           │
│                                                                │
│  Top Alerts:                                                   │
│  1. Authentication failure - 547 events                       │
│  2. File integrity monitoring - 203 events                    │
│  3. Rootcheck - 187 events                                    │
└────────────────────────────────────────────────────────────────┘
```

---

## 📥 Installing a Wazuh Agent

### Linux Agent Installation

```bash
# Step 1: Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | sudo tee -a /etc/apt/sources.list.d/wazuh.list

# Step 2: Install agent
sudo apt update
sudo apt install -y wazuh-agent

# Step 3: Configure manager IP
sudo sed -i "s/MANAGER_IP/[YOUR_WAZUH_SERVER_IP]/g" /var/ossec/etc/ossec.conf

# Step 4: Register and start agent
sudo /var/ossec/bin/agent-auth -m [WAZUH_SERVER_IP]
sudo systemctl start wazuh-agent
sudo systemctl enable wazuh-agent

# Step 5: Verify agent status
sudo systemctl status wazuh-agent
```

**Expected Output:**
```
● wazuh-agent.service - Wazuh agent
   Loaded: loaded (/lib/systemd/system/wazuh-agent.service)
   Active: active (running) since Mon 2025-08-18 11:00:00 UTC
```

---

## 🔍 Creating Custom Detection Rules

### Rule File Location
```bash
/var/ossec/etc/rules/local_rules.xml
```

### Example: Brute Force Detection Rule

```xml
<!-- File: /var/ossec/etc/rules/local_rules.xml -->
<group name="syslog,sshd,">

  <!-- Detect SSH brute force: 5 failed logins in 60 seconds -->
  <rule id="100001" level="10" frequency="5" timeframe="60">
    <if_matched_sid>5760</if_matched_sid>
    <same_source_ip />
    <description>SSH brute force attack: Multiple failed logins from same IP</description>
    <mitre>
      <id>T1110</id>
    </mitre>
    <group>authentication_failures,pci_dss_10.2.4,pci_dss_10.2.5,</group>
  </rule>

  <!-- Detect Log4Shell exploitation attempt -->
  <rule id="100002" level="15">
    <if_group>web</if_group>
    <url_match>\$\{jndi:</url_match>
    <description>Log4Shell exploitation attempt detected (CVE-2021-44228)</description>
    <mitre>
      <id>T1190</id>
    </mitre>
    <group>attack,</group>
  </rule>

</group>
```

```bash
# Restart Wazuh to apply new rules
sudo systemctl restart wazuh-manager

# Test rules syntax
sudo /var/ossec/bin/ossec-logtest
```

---

## 📊 Creating a Dashboard in Wazuh

### Step-by-Step: Alert Priority Pie Chart

**Step 1:** Go to **Wazuh Dashboard → Dashboards → Create New Dashboard**

**Step 2:** Click **"Add Panel"** → **"Visualization"**

**Step 3:** Select **"Pie Chart"** as chart type

**Step 4:** Configure data source:
```
Index Pattern:  wazuh-alerts-*
Metric:         Count
Buckets:        Terms → rule.level
  Ranges:
    Critical (12-15):  #FF0000
    High (8-11):       #FF8C00
    Medium (4-7):      #FFD700
    Low (0-3):         #00CED1
```

**Step 5:** Save dashboard as **"SOC-Week2-Alert-Priority"**

```
Screenshot Reference — Alert Priority Dashboard:
┌────────────────────────────────────────────────────────────────┐
│  SOC Week 2 — Alert Priority Dashboard            [Last 24h]  │
│  ─────────────────────────────────────────────────────────     │
│                                                                │
│   Alert Severity Distribution        Alert Trend (24h)        │
│   ┌─────────────────┐               ┌───────────────────┐     │
│   │        ░░       │               │    ▂▄█▄▂          │     │
│   │     ░░░░░░░     │               │  ▂████████▄       │     │
│   │   ░░░████░░░░   │               │ ▂█████████████▄   │     │
│   │  ░░░░██████░░   │  ■ Critical   │___________________│     │
│   │   ░░░████░░░    │  ■ High       │  00:00        24:00│    │
│   │     ░░░░░░░     │  ■ Medium                          │     │
│   │        ░        │  ■ Low        Top Rules Triggered: │     │
│   └─────────────────┘               ┌───────────────────┐     │
│   Critical: 45  (3.6%)              │ SSH Brute Force 547│     │
│   High:    203  (16.3%)             │ FIM Changes     203│     │
│   Medium:  587  (47.1%)             │ Rootcheck       187│     │
│   Low:     412  (33.0%)             └───────────────────┘     │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔔 Setting Up Active Response (IP Blocking)

```xml
<!-- Add to /var/ossec/etc/ossec.conf -->
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100001</rules_id>     <!-- Brute force rule -->
  <timeout>600</timeout>          <!-- Block for 10 minutes -->
</active-response>
```

```bash
# Verify active response is working
sudo cat /var/ossec/logs/active-responses.log
```

---

## 📋 Common Wazuh CLI Commands

```bash
# Check agent list and status
sudo /var/ossec/bin/agent_control -l

# View real-time alerts
sudo tail -f /var/ossec/logs/alerts/alerts.log

# View JSON format alerts
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool

# Search for specific alerts
sudo grep "brute force" /var/ossec/logs/alerts/alerts.log

# Check Wazuh manager status
sudo /var/ossec/bin/ossec-control status

# Restart all Wazuh services
sudo /var/ossec/bin/ossec-control restart

# Check ruleset
sudo /var/ossec/bin/ossec-logtest -V
```
