<#
.SYNOPSIS
    Audit, enforce, or roll back legacy TLS protocol settings via Schannel.
.DESCRIPTION
    Disables TLS 1.0/1.1 and explicitly enables TLS 1.2 for both Server and
    Client roles. Closes Tenable plugins 104743 / 157288. Idempotent.
    A reboot is required for Schannel changes to take effect.
.EXAMPLE
    .\Set-TlsProtocols.ps1 -Audit
    .\Set-TlsProtocols.ps1 -Enforce
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$Enforce,
    [switch]$Rollback
)

$Base = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
$Roles = 'Server', 'Client'

function Set-Protocol {
    param([string]$Protocol, [bool]$Enabled)
    foreach ($role in $Roles) {
        $path = Join-Path $Base "$Protocol\$role"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess("$Protocol/$role", "Enabled=$([int]$Enabled)")) {
            Set-ItemProperty $path -Name 'Enabled' -Value ([int]$Enabled) -Type DWord
            Set-ItemProperty $path -Name 'DisabledByDefault' -Value ([int](-not $Enabled)) -Type DWord
        }
    }
}

function Get-ProtocolState {
    foreach ($protocol in 'TLS 1.0', 'TLS 1.1', 'TLS 1.2') {
        foreach ($role in $Roles) {
            $path = Join-Path $Base "$protocol\$role"
            $enabled = (Get-ItemProperty $path -Name 'Enabled' -ErrorAction SilentlyContinue).Enabled
            [PSCustomObject]@{
                Protocol = $protocol
                Role     = $role
                Enabled  = if ($null -eq $enabled) { 'OS default' } else { [bool]$enabled }
            }
        }
    }
}

if ($Audit -or (-not $Enforce -and -not $Rollback)) {
    $state = Get-ProtocolState
    $state | Format-Table -AutoSize
    $legacyOn = $state | Where-Object { $_.Protocol -ne 'TLS 1.2' -and $_.Enabled -ne $false }
    if ($legacyOn) {
        Write-Host 'NON-COMPLIANT: legacy TLS not explicitly disabled.' -ForegroundColor Yellow
        exit 1
    }
    Write-Host 'COMPLIANT: TLS 1.0/1.1 disabled.' -ForegroundColor Green
    exit 0
}

if ($Enforce) {
    Set-Protocol 'TLS 1.0' $false
    Set-Protocol 'TLS 1.1' $false
    Set-Protocol 'TLS 1.2' $true
} else {
    Set-Protocol 'TLS 1.0' $true
    Set-Protocol 'TLS 1.1' $true
}

Get-ProtocolState | Format-Table -AutoSize
Write-Host 'REBOOT REQUIRED for Schannel changes to take effect.' -ForegroundColor Cyan
