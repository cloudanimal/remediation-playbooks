# Remediation Playbooks

A curated library of vulnerability remediation scripts and runbooks, built from patterns used to run an enterprise vulnerability management program at scale.

Every playbook follows the same structure — because a fix you can't validate or roll back isn't a fix, it's a gamble:

1. **Detect** — confirm the finding applies before touching anything
2. **Fix** — idempotent script, safe to re-run
3. **Validate** — prove the finding is closed
4. **Rollback** — undo it if something breaks

## Index

### Windows

| Playbook | Closes findings for |
|---|---|
| [smb-signing-enforcement](windows/smb-signing-enforcement/) | SMB signing not required (relay attacks; Tenable 57608) |
| [tls-legacy-protocol-disable](windows/tls-legacy-protocol-disable/) | TLS 1.0/1.1 enabled (Tenable 104743, 157288) |
| [print-spooler-hardening](windows/print-spooler-hardening/) | PrintNightmare-class spooler exposure (CVE-2021-34527 et al.) |
| [llmnr-netbios-disable](windows/llmnr-netbios-disable/) | LLMNR/NBT-NS poisoning exposure (Responder-class attacks) |

### Linux

| Playbook | Closes findings for |
|---|---|
| [openssh-hardening](linux/openssh-hardening/) | Weak SSH ciphers/MACs/KEX, root login enabled (Tenable 70658, 71049) |

### Browsers

| Playbook | Closes findings for |
|---|---|
| [chromium-update-enforcement](browsers/chromium-update-enforcement/) | Perpetually outdated Chrome/Edge (the finding that never stays fixed) |

### CVE-specific

| Playbook | CVE |
|---|---|
| [cve-2021-44228-log4shell](cves/cve-2021-44228-log4shell/) | Log4Shell — find log4j-core anywhere on disk, including nested in fat JARs |
| [cve-2020-1472-zerologon](cves/cve-2020-1472-zerologon/) | Zerologon — DC enforcement state + legacy-device event audit |
| [cve-2013-3900-winverifytrust](cves/cve-2013-3900-winverifytrust/) | The 13-year-old Authenticode finding that never dies (string-vs-DWORD trap included) |
| [cve-2022-30190-follina](cves/cve-2022-30190-follina/) | MSDT handler removal — the compensating-control pattern |
| [cve-2025-53779-badsuccessor](cves/cve-2025-53779-badsuccessor/) | BadSuccessor — OU CreateChild ACL audit (the permission nobody checks) |
| [cve-2024-6387-regresshion](cves/cve-2024-6387-regresshion/) | regreSSHion — backport-aware version check + bridge mitigation |
| [cve-2023-23397-outlook](cves/cve-2023-23397-outlook/) | Outlook NTLM leak — durable egress controls for the whole attack class |
| [cve-2023-4966-citrixbleed](cves/cve-2023-4966-citrixbleed/) | Citrix Bleed — the patch-isn't-enough runbook (kill the sessions) |
| [smbv1-removal-ms17-010](cves/smbv1-removal-ms17-010/) | EternalBlue class — two-phase SMBv1 removal with usage auditing |

Also see **[CATALOG.md](CATALOG.md)** — the full map of CVEs with PowerShell-scriptable remediations, including planned playbooks.

### Briefings

[`briefings/`](briefings/) — monthly Patch Tuesday triage notes, generated with my [patch-tuesday-analyzer](https://github.com/cloudanimal/patch-tuesday-analyzer).

## Ground rules

- **Test in a ring first.** Every script here is written to be deployed via your patch/config tooling (SCCM, Endpoint Central, GPO, Ansible) to a pilot group before broad rollout.
- **Idempotent by design.** Safe to re-run; scripts check state before changing it.
- **Rollback included.** Each playbook documents the exact undo path.

## Related

- [vuln-prioritization-toolkit](https://github.com/cloudanimal/vuln-prioritization-toolkit) — decide *what* to fix first
- [vm-metrics-dashboard](https://github.com/cloudanimal/vm-metrics-dashboard) — measure whether fixing is working

## License

MIT
