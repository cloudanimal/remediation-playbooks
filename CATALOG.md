# CVE → PowerShell Remediation Catalog

CVEs and finding families where the remediation or a meaningful mitigation is **scriptable with PowerShell** (registry, service, feature, ACL, or firewall state) rather than purely "install the patch." These are the ones a remediation team can close at scale with config management.

Status: ✅ playbook in this repo · 🔜 planned · 📖 documented approach below

## Authentication & relay attacks

| CVE / Finding | Name | PowerShell remediation | Status |
|---|---|---|---|
| Tenable 57608 | SMB signing not required | `RequireSecuritySignature` registry (server+client) | ✅ [playbook](windows/smb-signing-enforcement/) |
| CVE-2020-1472 | Zerologon | `FullSecureChannelProtection` + event audit on DCs | ✅ [playbook](cves/cve-2020-1472-zerologon/) |
| CVE-2023-23397 | Outlook NTLM leak | WebClient disable + outbound 445 block | ✅ [playbook](cves/cve-2023-23397-outlook/) |
| CVE-2021-36942 | PetitPotam (LSA spoofing) | Same egress controls + EPA on AD CS (`certutil`/IIS config) | 📖 use the 23397 playbook for egress; EPA separately |
| LLMNR/NBT-NS | Responder-class poisoning | `EnableMulticast=0` + `NetbiosOptions=2` | ✅ [playbook](windows/llmnr-netbios-disable/) |
| CVE-2021-42278/42287 | noPac / sAMAccountName spoofing | Patch + `ms-DS-MachineAccountQuota=0` via Set-ADDomain | 🔜 |
| CVE-2022-26925 | LSA spoofing (PetitPotam variant) | Patch + NTLM egress controls | 📖 covered by 23397 pattern |

## Protocol & cipher hygiene

| CVE / Finding | Name | PowerShell remediation | Status |
|---|---|---|---|
| Tenable 104743 | TLS 1.0/1.1 enabled | Schannel registry | ✅ [playbook](windows/tls-legacy-protocol-disable/) |
| CVE-2017-0144 | EternalBlue / SMBv1 | Feature removal + usage auditing | ✅ [playbook](cves/smbv1-removal-ms17-010/) |
| CVE-2016-2183 | SWEET32 (3DES) | Schannel cipher order / disable 3DES | 🔜 extend TLS playbook |
| CVE-2013-2566 | RC4 ciphers | Schannel `RC4*` keys | 🔜 extend TLS playbook |

## Privilege escalation & service hardening

| CVE / Finding | Name | PowerShell remediation | Status |
|---|---|---|---|
| CVE-2021-34527 | PrintNightmare | Spooler disable / Point-and-Print restriction | ✅ [playbook](windows/print-spooler-hardening/) |
| CVE-2025-53779 | BadSuccessor (dMSA) | Patch + OU `CreateChild` ACL audit | ✅ [playbook](cves/cve-2025-53779-badsuccessor/) |
| CVE-2021-36934 | HiveNightmare / SeriousSAM | `icacls` reset on `%windir%\system32\config` + VSS cleanup | 🔜 |
| CVE-2013-3900 | WinVerifyTrust padding | `EnableCertPaddingCheck` (REG_SZ!) | ✅ [playbook](cves/cve-2013-3900-winverifytrust/) |
| CVE-2022-30190 | Follina (MSDT) | Protocol handler removal w/ backup | ✅ [playbook](cves/cve-2022-30190-follina/) |
| CVE-2019-0708 | BlueKeep | Patch + enforce NLA (`UserAuthentication=1`) | 🔜 |

## Update plumbing & perpetual findings

| CVE / Finding | Name | PowerShell remediation | Status |
|---|---|---|---|
| Chrome/Edge < current | Perpetually outdated browsers | Update service + policy repair | ✅ [playbook](browsers/chromium-update-enforcement/) |
| Old Java/Adobe families | Same pattern, different updater | Updater service/task repair | 🔜 |

## Speculative execution (registry-controlled)

| CVE / Finding | Name | PowerShell remediation | Status |
|---|---|---|---|
| CVE-2017-5715 et al. | Spectre/Meltdown mitigations | `FeatureSettingsOverride` registry per MS guidance | 📖 settings vary by CPU generation — follow KB4073119 |

## Not PowerShell-fixable (know the difference)

Patch-only or appliance findings where scripting buys you detection, not remediation: Citrix Bleed ([runbook](cves/cve-2023-4966-citrixbleed/)), Log4Shell ([detection script](cves/cve-2021-44228-log4shell/), bash), regreSSHion ([check](cves/cve-2024-6387-regresshion/), bash), Exchange ProxyLogon/ProxyShell (patch + IIS rewrite mitigations), most firmware/appliance CVEs. Putting these in a "config fix" bucket on a remediation plan is how SLAs get missed — classify them honestly.
