# OpenSSH Hardening

**Closes:** weak SSH cipher/MAC/KEX findings (Tenable 70658, 71049), root login enabled, and related SSH configuration findings.

## Why it matters

Default sshd configs on older distros still offer CBC ciphers, SHA-1 MACs, and legacy key exchange. Scanners flag them forever; auditors copy them into every report. One config drop closes the whole family.

## Detect

```bash
sudo ./harden-sshd.sh --audit
```

## Fix

```bash
sudo ./harden-sshd.sh --enforce
```

Installs a drop-in at `/etc/ssh/sshd_config.d/99-hardening.conf` (no edits to the main config), validates with `sshd -t`, and reloads. The original state is preserved automatically — rollback just removes the drop-in.

## Validate

```bash
sudo ./harden-sshd.sh --audit
# or from another host:
nmap --script ssh2-enum-algos -p 22 <host>
```

## Rollback

```bash
sudo ./harden-sshd.sh --rollback
```

## Gotchas

- **Keep your session open** while reloading sshd; verify a *new* session connects before logging out.
- Very old SSH clients (legacy appliances, ancient Jenkins agents) may not support the modern algorithm set — check `auth.log` for negotiation failures in the pilot ring.
- Distros without `sshd_config.d` support (CentOS 7 and older) need the include added to the main config; the script detects and warns.
