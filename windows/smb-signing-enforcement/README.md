# SMB Signing Enforcement

**Closes:** "Microsoft Windows SMB Signing not required" (Tenable plugin 57608) — the finding behind SMB relay attacks (NTLM relay to SMB).

## Why it matters

Without required signing, an attacker on the network path can relay captured NTLM authentication to your servers and execute commands as the relayed user. This is a standard step in nearly every internal pentest report for a reason.

## Detect

```powershell
.\Set-SmbSigning.ps1 -Audit
```

## Fix

```powershell
# Pilot first. Deploy via SCCM/Endpoint Central/GPO to a test ring.
.\Set-SmbSigning.ps1 -Enforce
```

Sets `RequireSecuritySignature = 1` for both the SMB **server** (inbound) and **client** (outbound) roles.

## Validate

Re-run with `-Audit` (should report compliant), then rescan. Plugin 57608 closes on the next authenticated scan.

## Rollback

```powershell
.\Set-SmbSigning.ps1 -Rollback
```

## Gotchas

- Legacy NAS devices and very old print servers that can't sign will fail to connect to enforcing clients. Inventory SMB1/legacy dependencies first.
- Negligible CPU cost on modern hardware; the "signing hurts performance" objection is from a different decade.
