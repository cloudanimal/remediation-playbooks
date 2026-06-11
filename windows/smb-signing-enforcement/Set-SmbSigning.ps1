<#
.SYNOPSIS
    Audit, enforce, or roll back SMB signing requirements (server + client).
.DESCRIPTION
    Closes Tenable plugin 57608 (SMB Signing not required). Idempotent.
    Run with -Audit first; deploy -Enforce to a pilot ring before broad rollout.
.EXAMPLE
    .\Set-SmbSigning.ps1 -Audit
    .\Set-SmbSigning.ps1 -Enforce
    .\Set-SmbSigning.ps1 -Rollback
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$Enforce,
    [switch]$Rollback
)

$Server = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
$Client = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
$Name   = 'RequireSecuritySignature'

function Get-State {
    [PSCustomObject]@{
        ServerRequired = [bool](Get-ItemProperty $Server -Name $Name -ErrorAction SilentlyContinue).$Name
        ClientRequired = [bool](Get-ItemProperty $Client -Name $Name -ErrorAction SilentlyContinue).$Name
    }
}

if ($Audit -or (-not $Enforce -and -not $Rollback)) {
    $state = Get-State
    $state | Format-List
    if ($state.ServerRequired -and $state.ClientRequired) {
        Write-Host 'COMPLIANT: SMB signing required for server and client.' -ForegroundColor Green
        exit 0
    }
    Write-Host 'NON-COMPLIANT: SMB signing not fully required.' -ForegroundColor Yellow
    exit 1
}

$value = if ($Enforce) { 1 } else { 0 }
$action = if ($Enforce) { 'Enforce' } else { 'Rollback' }

foreach ($path in @($Server, $Client)) {
    if ($PSCmdlet.ShouldProcess($path, "$action $Name=$value")) {
        Set-ItemProperty -Path $path -Name $Name -Value $value -Type DWord
    }
}

Write-Host "$action complete. Current state:" -ForegroundColor Cyan
Get-State | Format-List
Write-Host 'Note: the LanmanWorkstation change takes effect after service restart or reboot.'
