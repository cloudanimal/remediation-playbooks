# CVE → PowerShell Remediation Catalog

CVEs and finding families where the remediation or a meaningful mitigation is **scriptable with PowerShell** (registry, service, feature, ACL, or firewall state) rather than purely "install the patch." These are the ones a remediation team can close at scale with config management — and every one below has a working playbook in this repo.

## Authentication & relay attacks

| CVE / Finding | Name | PowerShell remediation | Playbook |
|---|---|---|---|
| Tenable 57608 | SMB signing not required | `RequireSecuritySignature` registry (server+client) | [link](windows/smb-signing-enforcement/) |
| CVE-2020-1472 | Zerologon | `FullSecureChannelProtection` + event audit on DCs | [link](cves/cve-2020-1472-zerologon/) |
| CVE-2023-23397 | Outlook NTLM leak | WebClient disable + outbound 445 block | [link](cves/cve-2023-23397-outlook/) |
| LLMNR/NBT-NS | Responder-class poisoning | `EnableMulticast=0` + `NetbiosOptions=2` | [link](windows/llmnr-netbios-disable/) |

## Protocol & cipher hygiene

| CVE / Finding | Name | PowerShell remediation | Playbook |
|---|---|---|---|
| Tenable 104743 | TLS 1.0/1.1 enabled | Schannel registry | [link](windows/tls-legacy-protocol-disable/) |
| CVE-2017-0144 | EternalBlue / SMBv1 | Feature removal + usage auditing | [link](cves/smbv1-removal-ms17-010/) |

## Privilege escalation & service hardening

| CVE / Finding | Name | PowerShell remediation | Playbook |
|---|---|---|---|
| CVE-2021-34527 | PrintNightmare | Spooler disable / Point-and-Print restriction | [link](windows/print-spooler-hardening/) |
| CVE-2025-53779 | BadSuccessor (dMSA) | Patch + OU `CreateChild` ACL audit | [link](cves/cve-2025-53779-badsuccessor/) |
| CVE-2013-3900 | WinVerifyTrust padding | `EnableCertPaddingCheck` (REG_SZ!) | [link](cves/cve-2013-3900-winverifytrust/) |
| CVE-2022-30190 | Follina (MSDT) | Protocol handler removal w/ backup | [link](cves/cve-2022-30190-follina/) |

## Update plumbing & perpetual findings

| CVE / Finding | Name | PowerShell remediation | Playbook |
|---|---|---|---|
| Chrome/Edge < current | Perpetually outdated browsers | Update service + policy repair | [link](browsers/chromium-update-enforcement/) |

## Not PowerShell-fixable (know the difference)

Patch-only or appliance findings where scripting buys you detection, not remediation: Citrix Bleed ([runbook](cves/cve-2023-4966-citrixbleed/)), Log4Shell ([detection script](cves/cve-2021-44228-log4shell/), bash), regreSSHion ([check](cves/cve-2024-6387-regresshion/), bash), Exchange ProxyLogon/ProxyShell (patch + IIS rewrite mitigations), most firmware/appliance CVEs. Putting these in a "config fix" bucket on a remediation plan is how SLAs get missed — classify them honestly.
