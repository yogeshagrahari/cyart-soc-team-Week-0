# 📅 Week 2 — Alert Prioritization, Incident Classification & Basic Incident Response

> **Module:** SOC Fundamentals — Week 2  
> **Focus:** Alert Priority Levels · Incident Classification · Basic Incident Response  
> **Tools:** Wazuh · TheHive · Velociraptor · FTK Imager · VirusTotal · AlienVault OTX · Metasploit · CrowdSec

---

## 🗂️ Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Alert Priority Levels](./01-Alert-Priority-Levels/README.md) | CVSS scoring, severity definitions, prioritization criteria |
| 2 | [Incident Classification](./02-Incident-Classification/README.md) | MITRE ATT&CK mapping, taxonomy, metadata enrichment |
| 3 | [Basic Incident Response](./03-Basic-Incident-Response/README.md) | IR lifecycle phases, procedures, SOAR overview |
| 4 | [Alert Management Practice](./04-Alert-Management-Practice/README.md) | Wazuh dashboard, TheHive tickets, Google Sheets tracker |
| 5 | [Response Documentation](./05-Response-Documentation/README.md) | IR templates, checklists, post-mortem |
| 6 | [Alert Triage Practice](./06-Alert-Triage-Practice/README.md) | Wazuh triage, VirusTotal, AlienVault OTX |
| 7 | [Evidence Preservation](./07-Evidence-Preservation/README.md) | Velociraptor forensics, FTK Imager, chain of custody |
| 8 | [Capstone Project](./08-Capstone-Project/README.md) | Full attack-to-response simulation with Metasploit & Wazuh |

---

## 🎯 Learning Objectives

By the end of Week 2, you will be able to:

- [x] Assign CVSS-based severity scores to alerts
- [x] Classify incidents using MITRE ATT&CK and VERIS frameworks
- [x] Execute all 6 phases of the NIST SP 800-61 IR lifecycle
- [x] Create and manage incident tickets in TheHive
- [x] Perform alert triage using Wazuh + threat intelligence tools
- [x] Collect and preserve digital evidence with Velociraptor & FTK Imager
- [x] Conduct a full end-to-end incident response simulation

---

## ⚙️ Lab Environment Requirements

```
Host OS       : Kali Linux / Ubuntu 22.04 (recommended)
RAM           : Minimum 8 GB (16 GB recommended)
Storage       : 50 GB free disk space
Virtualization: VirtualBox or VMware Workstation

VMs Needed:
  ├── Wazuh Server (OVA or Docker)
  ├── Metasploitable2 (Target VM)
  ├── Windows 10 (Evidence Collection)
  └── Kali Linux (Attacker VM)
```

---

## 🔗 Key References

- [NIST SP 800-61 Rev 2](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)
- [MITRE ATT&CK Framework](https://attack.mitre.org)
- [FIRST CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [SANS Incident Handler's Handbook](https://www.sans.org/white-papers/33901/)
- [Wazuh Documentation](https://documentation.wazuh.com)
- [Velociraptor Docs](https://docs.velociraptor.app)
