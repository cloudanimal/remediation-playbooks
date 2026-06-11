# Chromium Update Enforcement

**Closes:** the perpetual "Google Chrome < x.y.z" / "Microsoft Edge < x.y.z" findings — the ones that come back every month because update services get disabled or broken.

## Why it matters

Chromium zero-days ship monthly (CVE-2025-5419 was a typical example: RCE, exploited in the wild before most orgs patched). The root cause of perpetually-outdated browsers is almost never "we forgot to patch" — it's broken update plumbing: disabled services, GPO overrides, or stuck installers. This playbook fixes the plumbing.

## Detect

```powershell
.\Repair-BrowserUpdates.ps1 -Audit
```

Reports installed Chrome/Edge versions, update service states, and any update-blocking policies.

## Fix

```powershell
.\Repair-BrowserUpdates.ps1 -Repair
```

- Re-enables and starts Google Update / Edge Update services
- Removes registry policies that pin or disable updates (`UpdateDefault=0`, version pins)
- Triggers an immediate update check

## Validate

`-Audit` again after ~10 minutes; versions should match current stable. The scanner finding closes on next scan.

## Gotchas

- If your org intentionally pins browser versions for an app-compat reason, **don't run -Repair** — fix the app instead; pinned browsers are standing zero-day exposure.
- VDI golden images need this run in the image, not the clones.
