# 01 — Alert Priority Levels

> Goal: Understand and apply severity/priority levels to incoming SOC alerts using CVSS scoring and asset criticality.

##  Theory Notes

### 1.1 Priority Definitions

| Priority | Severity | Response Time | Example |
|----------|----------|---------------|---------|
| **P1 — Critical** | Active threat causing immediate damage | ≤ 15 minutes | Ransomware encrypting files, Active data exfiltration |
| **P2 — High** | Threat with high exploit potential | ≤ 1 hour | Unauthorized admin access, Known CVE being exploited |
| **P3 — Medium** | Suspicious activity, low immediate risk | ≤ 4 hours | Port scanning, Failed login spikes |
| **P4 — Low** | Informational / Noise | ≤ 24 hours | Outdated software detected, Single failed SSH login |

---

### 1.2 CVSS Scoring System (v3.1)

The Common Vulnerability Scoring System (CVSS)** is the standard for rating vulnerability severity.

#### CVSS v3.1 Score Ranges

```
Score Range     Severity
─────────────────────────
0.0             None
0.1 – 3.9       Low
4.0 – 6.9       Medium
7.0 – 8.9       High
9.0 – 10.0      Critical
```

#### CVSS Base Metrics Explained

```
Attack Vector (AV):
  Network (N)       → Exploitable remotely     [highest risk]
  Adjacent (A)      → Requires local network
  Local (L)         → Requires local access
  Physical (P)      → Requires physical access  [lowest risk]

Attack Complexity (AC):
  Low (L)           → No special conditions
  High (H)          → Special conditions needed

Privileges Required (PR):
  None (N)          → No auth needed
  Low (L)           → Low-level auth
  High (H)          → Admin auth needed

User Interaction (UI):
  None (N)          → No user needed
  Required (R)      → User must take action

Scope (S):
  Unchanged (U)     → Impact confined to component
  Changed (C)       → Impact spreads beyond component

Confidentiality / Integrity / Availability Impact:
  None (N) / Low (L) / High (H)
```

#### Real-World Example: Log4Shell (CVE-2021-44228)

```
CVE:              CVE-2021-44228
CVSS Score:       10.0 (CRITICAL)
Vector String:    CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H

Breakdown:
  Attack Vector:        Network    ← Exploitable from internet
  Attack Complexity:    Low        ← Trivial to exploit
  Privileges Required:  None       ← No authentication needed
  User Interaction:     None       ← Fully automated exploitation
  Scope:                Changed    ← Can jump to other systems
  Confidentiality:      High       ← Full data access
  Integrity:            High       ← Can modify data
  Availability:         High       ← Can crash systems

SOC Priority:     P1 — CRITICAL (immediate response required)
```

---

### 1.3 Alert Prioritization Decision Framework

```
      INCOMING ALERT
            │
            |
            |
│ Step 1: Is there active exploitation?   │
│   YES → P1 Critical                     │
│   NO  → Continue to Step 2             │

             │
│ Step 2: Is a critical asset affected?   │
│   YES + CVSS ≥ 7.0  → P2 High          │
│   NO  → Continue to Step 3             │
              │

│ Step 3: Is there public exploit code?   │
│   YES + CVSS 4-6.9  → P2/P3            │
│   NO  → P3 or P4                       │
              │
│ Step 4: Business Impact Assessment      │
│   Financial / Regulatory → Escalate     │
│   Operational only → Standard IR       │

```

---

### 1.4 Asset Criticality Tiers

| Tier | Asset Type | Examples | Impact if Compromised |
|------|-----------|---------|----------------------|
| **Tier 1 — Crown Jewels** | Business-critical | Production DB, Payment servers, AD Domain Controllers | Catastrophic |
| **Tier 2 — Important** | High-value | Web servers, VPN gateways, Mail servers | Significant |
| **Tier 3 — Standard** | Regular operations | Developer workstations, Test VMs | Moderate |
| **Tier 4 — Low Value** | Non-critical | Printers, Guest Wi-Fi | Minimal |

---

## Practical: CVSS Scoring Exercise

### How to Use FIRST's CVSS Calculator

Step 1: Go to https://www.first.org/cvss/calculator/3.1

Step 2: Fill in the Base Score Metrics

Step 3: Document the vector string and score in your tracker.

---

##  Alert Priority Google Sheets Template

Create this spreadsheet to track and score alerts:

| Alert ID | Date/Time | Alert Description | Source IP | Asset Affected | Asset Tier | CVSS Score | Priority | Analyst | Status |
|----------|-----------|-------------------|-----------|----------------|-----------|-----------|---------|---------|--------|
| ALT-001 | 2025-08-18 11:00 | Log4Shell Exploit Attempt | 45.33.32.156 | prod-web-01 | Tier 1 | 10.0 | P1-Critical | Analyst-A | Open |
| ALT-002 | 2025-08-18 11:45 | Port Scan Detected | 192.168.1.200 | test-vm-03 | Tier 4 | 2.1 | P4-Low | Analyst-B | Closed |
| ALT-003 | 2025-08-18 12:30 | Unauthorized Admin Login | 10.0.0.55 | ad-dc-01 | Tier 1 | 8.8 | P2-High | Analyst-A | In Progress |

Google Sheets Formula for Auto-Priority:
```
=IF(F2>=9,"P1-Critical",IF(F2>=7,"P2-High",IF(F2>=4,"P3-Medium","P4-Low")))
```
(Put in column H, where F = CVSS Score)

---

##  Resources

- [FIRST CVSS v3.1 Guide](https://www.first.org/cvss/v3.1/specification-document)
- [NIST NVD CVSS Calculator](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)
- [CISA Log4Shell Advisory](https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-356a)
- [NIST SP 800-61 Rev 2](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)
