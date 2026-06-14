# Active Directory Setup

## Overview

Active Directory Domain Services (AD DS) is Microsoft's centralised directory service. It manages users, computers, and resources across a network under a single domain. In this lab, Windows Server 2022 is configured as the domain controller for `lab.local`, with Organizational Units and security groups structured to reflect a real company environment.

---

## Step 1 — Install the AD DS Role

Open **Server Manager** → **Add Roles and Features** → follow the wizard and select **Active Directory Domain Services**.

After installation completes, a notification flag appears in Server Manager. Click it and select **Promote this server to a domain controller**.

In the promotion wizard:
- Select **Add a new forest**
- Root domain name: `lab.local`
- Set a DSRM (Directory Services Restore Mode) password
- Accept the remaining defaults and complete the wizard

The server will restart automatically. After reboot, the login screen will reflect the domain (`LAB\Administrator`).

---

## Step 2 — Create Organizational Units (OUs)

Open **Active Directory Users and Computers** (search it from Start or via Server Manager → Tools).

Right-click `lab.local` → **New** → **Organizational Unit** and create three OUs:

```
lab.local
├── IT Department
├── Finance Department
└── HR Department
```

OUs are containers used to organise objects in AD and to scope Group Policy. In real environments, OU structure usually maps to departments, locations, or both.

---

## Step 3 — Create User Accounts

Inside each OU, right-click → **New** → **User**. Fill in the first name, last name, and logon name, then set a password.

Users created in this lab:

| OU | Username | Full Name |
|---|---|---|
| IT Department | haziq.it | Haziq IT |
| IT Department | ali.it | Ali IT |
| Finance Department | siti.finance | Siti Finance |
| Finance Department | abu.finance | Abu Finance |
| HR Department | rina.hr | Rina HR |
| HR Department | farid.hr | Farid HR |

On the password screen, tick **User must change password at next logon** — this is standard practice for new account provisioning.

---

## Step 4 — Create Security Groups

Inside each OU, right-click → **New** → **Group**.

| Group Name | Group Scope | Group Type |
|---|---|---|
| IT-Staff | Global | Security |
| Finance-Staff | Global | Security |
| HR-Staff | Global | Security |

After creating each group, open its **Properties** → **Members** tab and add the relevant users.

**Why groups matter:** In real environments, permissions are assigned to groups, not individuals. When someone joins a team, you add them to the group — they inherit all the access automatically. When they leave, you remove them from the group. This scales cleanly across hundreds or thousands of users.

---

## Why This Matters in IT Support

Active Directory is the backbone of identity management in most enterprise Windows environments. As an IT support professional, you'll interact with AD daily — resetting passwords, unlocking accounts, adding users to groups, and troubleshooting login issues. Understanding the structure (forest → domain → OU → user/group) is fundamental to doing that work confidently.
