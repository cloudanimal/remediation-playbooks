# Disable Legacy TLS (1.0 / 1.1)

**Closes:** "TLS Version 1.0/1.1 Protocol Detection" (Tenable plugins 104743, 157288).

## Why it matters

TLS 1.0/1.1 are deprecated (RFC 8996), fail compliance baselines (PCI DSS 4.0, NIST SP 800-52r2), and keep auditors writing the same finding every quarter. Most environments left them enabled out of inertia, not need.

## Detect

```powershell
.\Set-TlsProtocols.ps1 -Audit
```

## Fix

```powershell
.\Set-TlsProtocols.ps1 -Enforce
```

Disables TLS 1.0/1.1 (server + client Schannel registry keys) and ensures TLS 1.2 is explicitly enabled. **Reboot required** to take effect.

## Validate

`-Audit` after reboot, then rescan. From another host:
`nmap --script ssl-enum-ciphers -p 443 <host>` should show no TLSv1.0/1.1.

## Rollback

```powershell
.\Set-TlsProtocols.ps1 -Rollback   # re-enables 1.0/1.1, reboot required
```

## Gotchas

- **SQL Server pre-2016 / old .NET apps** may pin TLS 1.0. Check `SchUseStrongCrypto` for .NET and test app connectivity in your pilot ring.
- Legacy LDAPS clients, old Java (≤7) and ancient monitoring agents are the usual breakage suspects.
- This is the single most common "fix caused an outage" playbook in this library — pilot ring discipline matters here more than anywhere.
