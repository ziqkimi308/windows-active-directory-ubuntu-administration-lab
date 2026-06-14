# IT Support Lab — Project 3: Windows & Linux System Administration

A hands-on sysadmin lab covering Active Directory, Group Policy, Linux user management, shell scripting, and log analysis. Built on Windows Server 2022 and Ubuntu Server 26.04 in a VirtualBox isolated lab environment.

---

## What This Project Covers

| Area | Topics |
|---|---|
| Windows Server | Active Directory, Organizational Units, User & Group Management |
| Group Policy | Password Policy, Account Lockout, Audit Policy, OU-scoped Restrictions |
| Linux | User & Group Management, File Permissions, Directory Access Control |
| Scripting | Bash user audit script, PowerShell AD audit script, cron scheduling |
| Log Analysis | Windows Event Viewer (Event IDs 4624/4625/4720), Linux auth.log & journald |

---

## Lab Environment

- **Hypervisor:** VirtualBox
- **Network:** Internal Network (`labnet`) — isolated from host
- **Windows Server:** 2022 Evaluation (Desktop Experience), static IP `192.168.10.5`, domain `lab.local`
- **Ubuntu Server:** 26.04 LTS, reused from P2

---

## Project Structure

```
it-support-lab-p3/
├── README.md
├── docs/
│   ├── active-directory-setup.md
│   ├── group-policy-config.md
│   ├── linux-user-management.md
│   ├── shell-scripting.md
│   └── log-analysis.md
├── scripts/
│   ├── user-audit.sh
│   └── user-audit.ps1
└── screenshots/
```

---

## Phase 1 — Active Directory Setup

→ [Full documentation](docs/active-directory-setup.md)

Installed the **Active Directory Domain Services (AD DS)** role via Server Manager and promoted the server to a domain controller for `lab.local`.

Created three Organizational Units (OUs) to mirror a real company structure:

```
lab.local
├── IT Department     → haziq.it, ali.it
├── Finance Department → siti.finance, abu.finance
└── HR Department     → rina.hr, farid.hr
```

Each department has its own **security group** (`IT-Staff`, `Finance-Staff`, `HR-Staff`). Users are assigned to groups — not managed individually — which reflects how access control is handled at scale in real environments.

---

## Phase 2 — Group Policy

→ [Full documentation](docs/group-policy-config.md)

### Security-Baseline GPO (domain-wide)

Applied to `lab.local`. Configured under:
`Computer Configuration → Policies → Windows Settings → Security Settings`

**Password Policy**

| Setting | Value |
|---|---|
| Minimum password length | 10 characters |
| Maximum password age | 90 days |
| Password must meet complexity requirements | Enabled |

**Account Lockout Policy**

| Setting | Value |
|---|---|
| Account lockout threshold | 5 invalid logon attempts |
| Account lockout duration | 15 minutes |
| Reset lockout counter after | 10 minutes |

**Audit Policy** (Local Policies → Audit Policy)

| Setting | Value |
|---|---|
| Audit account logon events | Success, Failure |
| Audit logon events | Success, Failure |

### IT-Restrictions GPO (IT Department OU only)

Scoped to the `IT Department` OU to demonstrate that GPOs can target specific parts of the directory.

`User Configuration → Policies → Administrative Templates → System`

- **Prevent access to the command prompt** — Enabled (with script processing also disabled)

> **Note:** In a real production environment this restriction would apply to standard users (Finance, HR) or kiosk machines — not IT staff who depend on CLI tools daily. This is used here purely to demonstrate OU-scoped GPO targeting.

---

## Phase 3 — Linux User Management & Permissions

→ [Full documentation](docs/linux-user-management.md)

Created users and groups on Ubuntu Server 26.04 to mirror the Windows AD structure:

```bash
sudo groupadd it-staff
sudo groupadd finance-staff

sudo useradd -m -s /bin/bash haziq.it
sudo usermod -aG it-staff haziq.it
sudo passwd haziq.it

sudo useradd -m -s /bin/bash siti.finance
sudo usermod -aG finance-staff siti.finance
sudo passwd siti.finance
```

Set up department directories with group-based access control:

```bash
sudo mkdir -p /data/it /data/finance

sudo chown root:it-staff /data/it
sudo chmod 770 /data/it

sudo chown root:finance-staff /data/finance
sudo chmod 770 /data/finance
```

**Permission breakdown — `chmod 770`:**

| Who | Read | Write | Execute |
|---|---|---|---|
| Owner (root) | ✅ | ✅ | ✅ |
| Group members | ✅ | ✅ | ✅ |
| Others | ❌ | ❌ | ❌ |

**Cross-department access is denied** — `haziq.it` cannot read `/data/finance`, and `siti.finance` cannot read `/data/it`. Verified and documented in screenshots.

---

## Phase 4 — Shell Scripting & Automation

→ [Full documentation](docs/shell-scripting.md)

### Bash — User Audit Script ([`scripts/user-audit.sh`](scripts/user-audit.sh))

Generates a report of active users, groups, and recent logins. Scheduled via cron to run daily at 08:00 and append to `/var/log/user-audit.log`.

```bash
0 8 * * * /opt/scripts/user-audit.sh >> /var/log/user-audit.log 2>&1
```

### PowerShell — AD User Audit ([`scripts/user-audit.ps1`](scripts/user-audit.ps1))

Queries Active Directory for all user accounts and exports a CSV report to `C:\Reports\user-audit.csv`. Captures name, SAM account name, department, last logon date, and enabled status — a real script used by IT admins for periodic access reviews.

---

## Phase 5 — Log Analysis

→ [Full documentation](docs/log-analysis.md)

With audit policies enabled in Phase 2, the Security event log now captures logon and account activity. This phase queries those logs to confirm events are being recorded correctly, and does the equivalent on the Linux side using `auth.log` and `journalctl`.

### Windows Event Viewer

Filtered the Security log by Event ID to identify key authentication events:

| Event ID | Meaning | When to look for it |
|---|---|---|
| 4624 | Successful logon | Baseline activity; investigate after-hours or unusual accounts |
| 4625 | Failed logon | Repeated failures may indicate brute-force or credential stuffing |
| 4720 | User account created | Should always match an approved provisioning request |
| 4740 | Account locked out | Follow up to confirm user error vs. active attack |

### Linux Auth Logs

Ubuntu 26.04 uses `systemd-journald` as the primary logging backend. The traditional `/var/log/auth.log` may exist but is not guaranteed on minimal installs.

```bash
# Traditional approach (works if rsyslog is installed)
sudo tail -50 /var/log/auth.log
sudo grep "Failed password" /var/log/auth.log

# Modern approach — always available on Ubuntu 26.04
sudo journalctl _SYSTEMD_UNIT=sshd.service
sudo journalctl | grep "Failed password"
```

Both approaches are documented — showing awareness of the ongoing transition from syslog to journald in modern Ubuntu.

---

## Key Concepts (Interview Ready)

**What is Active Directory and why do companies use it?**
AD is Microsoft's directory service for centralised identity and access management. It lets admins manage users, computers, and permissions from a single place rather than configuring each machine individually.

**What is a GPO and how does it get applied?**
A Group Policy Object is a set of configuration rules applied to users or computers in an AD domain. GPOs are linked to OUs, sites, or the domain itself, and are processed at startup (computer policy) or login (user policy).

**What is the difference between `chmod 770` and `chmod 777`?**
`chmod 770` grants full access to the owner and group only — everyone else is denied. `chmod 777` grants full access to all users including unauthenticated or low-privilege ones, which is a security risk and should almost never be used in production.

**How would you find out who last logged into a Linux server?**
Run `last` to see recent login history, or `sudo journalctl _SYSTEMD_UNIT=sshd.service` for SSH-based logins on modern Ubuntu.

**What Event ID would you look for if someone's account was locked out?**
Event ID **4740** — Account Locked Out. Cross-reference with 4625 (failed logons) in the minutes prior to understand the cause.

---

## Skills Demonstrated

- Active Directory installation, domain promotion, and OU design
- Group Policy creation, linking, and OU-scoped targeting
- Linux user and group provisioning with `useradd`, `usermod`, `groupadd`
- File system permission management with `chown` and `chmod`
- Bash scripting and cron job scheduling
- PowerShell scripting with the `ActiveDirectory` module
- Windows Security Event Log analysis by Event ID
- Linux log analysis using both `auth.log` and `journalctl`
- Cross-platform documentation and portfolio writeup

---

## Notes

- Windows Server is running on an unactivated evaluation license — the "Activate Windows" watermark visible in some screenshots is expected and does not affect lab functionality.
- Ubuntu Server 26.04 ships with PHP 8.5 in its default repositories, which caused a compatibility issue in a separate project (osTicket). This project is unaffected.
- The `last` command required manual installation on the 26.04 minimal install: `sudo apt install last`