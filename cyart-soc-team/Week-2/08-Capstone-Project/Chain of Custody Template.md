# 🔗 Chain of Custody Template

## Purpose
This document tracks the collection, storage, and transfer of all digital evidence to maintain its admissibility and integrity.

---

```
╔══════════════════════════════════════════════════════════════════╗
║              DIGITAL EVIDENCE — CHAIN OF CUSTODY FORM           ║
╚══════════════════════════════════════════════════════════════════╝

CASE INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Incident ID:         INC-[YEAR]-[NUMBER]
Case Title:          ________________________________
Case Number:         CASE-[YEAR]-[NUMBER]
Investigating Team:  SOC / IR Team
Date Opened:         ________________________________

SOURCE SYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hostname:            ________________________________
IP Address:          ________________________________
Operating System:    ________________________________
System Role:         ________________________________
Location:            ________________________________

══════════════════════════════════════════════════════════════════
EVIDENCE ITEM [#]
══════════════════════════════════════════════════════════════════

Evidence ID:         EVD-[CASE]-[NUMBER]
Item Type:           [ ] Memory Dump  [ ] Disk Image  [ ] Log File
                     [ ] Network Cap  [ ] Registry    [ ] Other: ___
Filename:            ________________________________
File Size:           ________ bytes (________ GB/MB)

HASH VALUES (compute immediately upon collection):
  MD5:    ________________________________________________
  SHA256: ________________________________________________
           ________________________________________________

Collection Details:
  Collected By:      ________________________________
  Collection Date:   ________________________________
  Collection Time:   ________ UTC
  Collection Method: ________________________________
  Tool Used:         ________________________________
  Tool Version:      ________________________________
  Storage Location:  ________________________________

CUSTODY TRANSFER LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Transfer # | Date/Time (UTC) | Released By | Received By | Purpose | Signature |
|------------|-----------------|-------------|-------------|---------|-----------|
| 1 (Initial) | | SYSTEM | | Collection | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |

INTEGRITY VERIFICATION LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Each time evidence is accessed, verify hash matches:

| Date | Verified By | SHA256 Match? | Notes |
|------|-------------|---------------|-------|
| | | YES / NO | Initial collection |
| | | YES / NO | |
| | | YES / NO | |

══════════════════════════════════════════════════════════════════
CERTIFICATIONS
══════════════════════════════════════════════════════════════════

I certify that the information above is true and accurate, and that
this evidence was collected, handled, and stored in accordance with
forensic best practices to maintain its integrity.

Collected By:
  Name:        ________________________________
  Title:       ________________________________
  Date:        ________________________________
  Signature:   ________________________________

Reviewed By:
  Name:        ________________________________
  Title:       ________________________________
  Date:        ________________________________
  Signature:   ________________________________

══════════════════════════════════════════════════════════════════
NOTES / ADDITIONAL OBSERVATIONS
══════════════════════════════════════════════════════════════════
___________________________________________________________________
___________________________________________________________________
___________________________________________________________________
```
