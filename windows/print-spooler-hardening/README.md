# Print Spooler Hardening

**Closes:** PrintNightmare-class exposure (CVE-2021-34527, CVE-2021-1675 and successors) — and the steady drip of spooler CVEs that followed.

## Why it matters

The spooler runs as SYSTEM, is on by default everywhere, and is reachable over RPC. On servers that never print (most of them), it's pure attack surface. Domain controllers running the spooler are a classic privilege-escalation path.

## Decision tree

| Host type | Action |
|---|---|
| Domain controllers | **Disable** the service entirely |
| Servers that don't print | **Disable** the service entirely |
| Print servers | Keep, but restrict Point and Print (script does this) |
| Workstations | Keep, restrict Point and Print |

## Detect / Fix / Validate / Rollback

```powershell
.\Set-SpoolerHardening.ps1 -Audit
.\Set-SpoolerHardening.ps1 -DisableService      # DCs and non-printing servers
.\Set-SpoolerHardening.ps1 -RestrictPointAndPrint  # hosts that must print
.\Set-SpoolerHardening.ps1 -Rollback
```

## Gotchas

- Disabling the spooler also breaks **print-to-PDF** locally; users on shared RDS hosts will notice.
- Some LOB apps queue reports through the spooler even when no physical printer exists — pilot ring first.
