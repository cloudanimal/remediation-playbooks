# SMBv1 Removal — MS17-010 / EternalBlue class (CVE-2017-0144)

WannaCry and NotPetya rode EternalBlue in 2017. The patch is ancient history; the durable fix is removing SMBv1 entirely — yet it keeps reappearing via golden images, OS upgrades-in-place, and "temporary" re-enables for that one legacy scanner/copier that never got replaced.

## Detect

```powershell
.\Remove-Smb1.ps1 -Audit
```

Reports the SMBv1 feature state (server + client), whether the server is *configured* to accept SMB1, and — the part most checks skip — **recent SMB1 session activity from the audit log**, so you know if anything still uses it before you pull the plug.

## Fix

```powershell
.\Remove-Smb1.ps1 -EnableAuditing     # run this first; let it soak for 2-4 weeks
.\Remove-Smb1.ps1 -Remove             # then remove the feature
```

The two-phase approach is the playbook: audit SMB1 access for a few weeks, chase down whatever appears (it's always a multifunction printer or a 2008-era NAS), *then* remove.

## Validate

`-Audit` shows feature absent + protocol refused. Rescan clears the MS17-010/SMBv1 detection family.

## Rollback

```powershell
.\Remove-Smb1.ps1 -Restore    # reinstalls the feature (requires reboot)
```

If you find yourself running this, the real task is replacing whatever needed it.

## Gotchas

- Removal needs a **reboot** to complete on most SKUs.
- `Set-SmbServerConfiguration -EnableSMB1Protocol $false` alone leaves the binaries installed — scanners (correctly) still flag it. Remove the feature.
