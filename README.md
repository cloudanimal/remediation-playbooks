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
