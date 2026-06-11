<#
.SYNOPSIS
    Audit, remove, or restore SMBv1 (MS17-010 / EternalBlue exposure).
.DESCRIPTION
    Two-phase removal: -EnableAuditing first to log real SMB1 usage for a
    soak period, then -Remove. Disabling the protocol config alone leaves
    binaries installed and scanners still flag it - this removes the feature.
.EXAMPLE
    .\Remove-Smb1.ps1 -Audit
    .\Remove-Smb1.ps1 -EnableAuditing
    .\Remove-Smb1.ps1 -Remove
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$EnableAuditing,
    [switch]$Remove,
    [switch]$Restore
)

$Features = 'SMB1Protocol', 'SMB1Protocol-Client', 'SMB1Protocol-Server'

function Get-State {
    $features = foreach ($name in $Features) {
        Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction SilentlyContinue |
            Select-Object FeatureName, State
    }
    $config = Get-SmbServerConfiguration
    [PSCustomObject]@{
        Features          = $features
        ServerAcceptsSmb1 = $config.EnableSMB1Protocol
        AuditingEnabled   = $config.AuditSmb1Access
    }
}

function Get-RecentSmb1Sessions {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-SMBServer/Audit'; Id = 3000
        StartTime = (Get-Date).AddDays(-30)
    } -ErrorAction SilentlyContinue |
        ForEach-Object { ($_.Message -split "`n" | Select-String 'Client Address').ToString().Trim() } |
        Group-Object | Sort-Object Count -Descending | Select-Object Count, Name
}

if ($Audit -or (-not $EnableAuditing -and -not $Remove -and -not $Restore)) {
    $state = Get-State
    $state.Features | Format-Table -AutoSize
    Write-Host "Server accepts SMB1: $($state.ServerAcceptsSmb1)   Auditing: $($state.AuditingEnabled)"
    $sessions = Get-RecentSmb1Sessions
    if ($sessions) {
        Write-Host "`nSMB1 clients seen in last 30 days - fix these BEFORE removing:" -ForegroundColor Red
        $sessions | Format-Table -AutoSize
        exit 1
    }
    if ($state.Features.State -contains 'Enabled') {
        Write-Host 'NON-COMPLIANT: SMBv1 feature installed (no recent usage logged).' -ForegroundColor Yellow
        exit 1
    }
    Write-Host 'COMPLIANT: SMBv1 removed.' -ForegroundColor Green
    exit 0
}

if ($EnableAuditing) {
    if ($PSCmdlet.ShouldProcess('SMB server', 'Enable SMB1 access auditing')) {
        Set-SmbServerConfiguration -AuditSmb1Access $true -Force
        Write-Host 'Auditing on. Let it soak 2-4 weeks, then re-run -Audit before -Remove.'
    }
}

if ($Remove) {
    $sessions = Get-RecentSmb1Sessions
    if ($sessions) {
        Write-Warning 'SMB1 clients active in the last 30 days - removal will break them:'
        $sessions | Format-Table -AutoSize
    }
    if ($PSCmdlet.ShouldProcess('SMBv1', 'Disable config and remove feature')) {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        foreach ($name in $Features) {
            Disable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host 'SMBv1 removed. REBOOT REQUIRED to complete.' -ForegroundColor Cyan
    }
}

if ($Restore) {
    if ($PSCmdlet.ShouldProcess('SMBv1', 'Reinstall feature')) {
        foreach ($name in $Features) {
            Enable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host 'SMBv1 feature reinstalled (reboot required). Now go replace whatever needed it.' -ForegroundColor Yellow
    }
}
