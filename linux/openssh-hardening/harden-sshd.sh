#!/usr/bin/env bash
# Audit, enforce, or roll back OpenSSH hardening via a drop-in config.
# Closes weak cipher/MAC/KEX and root-login findings (Tenable 70658, 71049).
# Idempotent. Keep your current session open until you verify a new login works.
set -euo pipefail

DROPIN_DIR=/etc/ssh/sshd_config.d
DROPIN="$DROPIN_DIR/99-hardening.conf"

HARDENED_CONFIG='# Managed by remediation-playbooks/linux/openssh-hardening
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 4
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group-exchange-sha256
'

audit() {
    local fail=0
    if [[ -f "$DROPIN" ]]; then
        echo "Drop-in present: $DROPIN"
    else
        echo "Drop-in missing: $DROPIN"
        fail=1
    fi
    echo
    echo "Effective settings:"
    for key in permitrootlogin ciphers macs kexalgorithms; do
        sshd -T 2>/dev/null | grep -i "^$key " || true
    done
    if sshd -T 2>/dev/null | grep -qi '^permitrootlogin yes'; then
        echo "NON-COMPLIANT: root login permitted" >&2
        fail=1
    fi
    if sshd -T 2>/dev/null | grep -i '^ciphers' | grep -qE 'cbc|arcfour|3des'; then
        echo "NON-COMPLIANT: weak ciphers offered" >&2
        fail=1
    fi
    [[ $fail -eq 0 ]] && echo "COMPLIANT" || exit 1
}

enforce() {
    if [[ ! -d "$DROPIN_DIR" ]]; then
        echo "warning: $DROPIN_DIR not supported on this distro." >&2
        echo "Add 'Include /etc/ssh/sshd_config.d/*.conf' to /etc/ssh/sshd_config first." >&2
        exit 1
    fi
    printf '%s' "$HARDENED_CONFIG" > "$DROPIN"
    chmod 600 "$DROPIN"
    if ! sshd -t; then
        echo "error: config validation failed, removing drop-in" >&2
        rm -f "$DROPIN"
        exit 1
    fi
    systemctl reload sshd 2>/dev/null || systemctl reload ssh
    echo "Enforced. KEEP THIS SESSION OPEN and verify a new SSH session connects."
}

rollback() {
    rm -f "$DROPIN"
    sshd -t
    systemctl reload sshd 2>/dev/null || systemctl reload ssh
    echo "Rolled back: drop-in removed, sshd reloaded."
}

case "${1:-}" in
    --audit)    audit ;;
    --enforce)  enforce ;;
    --rollback) rollback ;;
    *) echo "usage: $0 --audit | --enforce | --rollback" >&2; exit 2 ;;
esac
