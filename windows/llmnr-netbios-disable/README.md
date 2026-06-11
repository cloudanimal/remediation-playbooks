# Disable LLMNR and NetBIOS Name Service

**Closes:** LLMNR/NBT-NS poisoning exposure — the protocols that make Responder-class credential-capture attacks work on internal networks.

## Why it matters

When DNS fails, Windows falls back to broadcasting name lookups via LLMNR and NBT-NS. Anyone on the subnet can answer, hand the victim a fake auth challenge, and capture NTLMv2 hashes. Disabling these legacy fallbacks is one of the highest-value, lowest-risk hardening wins available.

## Detect / Fix / Validate / Rollback

```powershell
.\Set-LegacyNameResolution.ps1 -Audit
.\Set-LegacyNameResolution.ps1 -Enforce
.\Set-LegacyNameResolution.ps1 -Rollback
```

Enforce disables LLMNR via policy registry and sets NetBIOS-over-TCP/IP to disabled (`NetbiosOptions = 2`) on all active network adapters.

## Validate

After enforcement, from another host on the subnet run Responder in analyze mode (`-A`, authorized testing only) — the host should no longer answer LLMNR/NBT-NS queries. Or simply confirm with `-Audit`.

## Gotchas

- Environments with **WINS** or apps relying on NetBIOS name resolution (rare but real in legacy manufacturing/healthcare networks) need DNS entries in place first.
- New network adapters get the OS default NetBIOS setting — deploy via your config management tool, not as a one-off, so the setting persists.
