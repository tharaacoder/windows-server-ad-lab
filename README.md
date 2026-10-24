# Windows Server Enterprise Lab: Active Directory for a Two-Site Company

A complete, documented infrastructure for a fictional international trading company (**Global Trade Corp**, ~45–60 employees, headquarters + one branch), built on **Windows Server 2022** in a **VMware** lab.

The goal was an infrastructure that is **secure, scalable, and has no single point of failure**, documented step by step so a new engineer can understand and rebuild it.

> **Note:** this is a lab (virtual machines). The branch is simulated: both domain controllers share one physical network, and the HQ/Branch separation is logical inside Active Directory. Names, users and IP addresses are fictional.

## Architecture

- **Domain / Forest:** `globaltrade.local` (single forest, single domain)
- **Servers:** two domain controllers (primary + additional) with AD-integrated DNS and replication between two AD Sites (`HQ-Site`, `Branch-Site`)
- **Clients:** Windows 10 clients joined to the domain
- **Addressing:** `192.168.1.0/24` (HQ); a documented `192.168.2.0/24` scope for the branch

## What was implemented

| Area | Work done |
|---|---|
| **Directory** | Forest/domain design, OU structure per site and department, naming convention, AD Sites and Services, replication checks |
| **Network services** | DNS (forward + reverse, AD-integrated), DHCP scopes per subnet with reservations |
| **Identity** | 45 users and 7 department groups created with PowerShell (duplicate-safe naming); Fine-Grained Password Policy for admins; account lockout policy |
| **Group Policy** | Screen lock, USB and Control Panel restriction, drive mapping, security filtering by group, firewall policy; results verified with `gpresult` |
| **Data** | Shared folders with NTFS + Share permissions (least privilege), Shadow Copies, FSRM quotas |
| **Security** | Windows Firewall with custom rules, BitLocker on a data volume, auditing of failed logons |
| **Resilience** | Windows Server Backup (System State + shared folders) with restore test, FSMO role seizure scenario, ransomware response plan |
| **Operations** | WSUS central update server, Performance Monitor data collector, Event Viewer review |

## Repository contents

```
reports/
  Reports_1-12.pdf    # tasks 1-12: design, DNS/DHCP, users, GPO, password policy, shares
  Reports_13-25.pdf   # tasks 13-25: Shadow Copies, FSRM, firewall, BitLocker, lockout, auditing,
                      #   backup/restore, WSUS, monitoring, event review, FSMO seizure, ransomware response
scripts/
  01-create-ous.ps1
  02-create-users-groups.ps1
  03-create-shared-folders.ps1
```

The reports are written in **Arabic** and contain step-by-step explanations with screenshots of every stage.

## Reproducing the scripts

Run on the domain controller, in PowerShell as Administrator, in this order:

1. `01-create-ous.ps1`
2. `02-create-users-groups.ps1` (prompts for the initial password; nothing sensitive is stored in the repo)
3. `03-create-shared-folders.ps1`

## Key lessons

- **Security is designed in from the start**, not added at the end.
- **Verify, don't assume.** For example, a firewall GPO did not apply to a client until the computer account was moved from the default `Computers` container into the linked OU; `gpresult` exposed this.
- **Good documentation** (screenshots and reports) is what makes a system understandable to the next engineer.

## Tools

Windows Server 2022, Active Directory, DNS, DHCP, Group Policy, FSRM, Windows Server Backup, WSUS, BitLocker, PowerShell, VMware Workstation.
