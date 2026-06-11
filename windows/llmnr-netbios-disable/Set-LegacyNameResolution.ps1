<#
.SYNOPSIS
    Audit, disable, or restore LLMNR and NetBIOS-over-TCP/IP.
.DESCRIPTION
    Closes LLMNR/NBT-NS poisoning exposure (Responder-class attacks).
    Idempotent; safe to re-run. Deploy via config management so new
    adapters inherit the setting.
.EXAMPLE
    .\Set-LegacyNameResolution.ps1 -Audit
    .\Set-LegacyNameResolution.ps1 -Enforce
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$Enforce,
    [switch]$Rollback
)

$LlmnrPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
$NbtBase   = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'

function Get-State {
    $llmnr = (Get-ItemProperty $LlmnrPath -Name 'EnableMulticast' -ErrorAction SilentlyContinue).EnableMulticast
    $nbt = Get-ChildItem $NbtBase | ForEach-Object {
        (Get-ItemProperty $_.PSPath -Name 'NetbiosOptions' -ErrorAction SilentlyContinue).NetbiosOptions
    }
    [PSCustomObject]@{
        LlmnrDisabled       = ($llmnr -eq 0)
        AdapterCount        = $nbt.Count
        NetbiosDisabledOn   = ($nbt | Where-Object { $_ -eq 2 }).Count
    }
}

if ($Audit -or (-not $Enforce -and -not $Rollback)) {
    $state = Get-State
    $state | Format-List
    if ($state.LlmnrDisabled -and $state.NetbiosDisabledOn -eq $state.AdapterCount) {
        Write-Host 'COMPLIANT: LLMNR and NetBIOS disabled.' -ForegroundColor Green
        exit 0
    }
    Write-Host 'NON-COMPLIANT: legacy name resolution still enabled.' -ForegroundColor Yellow
    exit 1
}

if ($Enforce) {
    if (-not (Test-Path $LlmnrPath)) { New-Item $LlmnrPath -Force | Out-Null }
    if ($PSCmdlet.ShouldProcess('LLMNR', 'Disable (EnableMulticast=0)')) {
        Set-ItemProperty $LlmnrPath -Name 'EnableMulticast' -Value 0 -Type DWord
    }
    foreach ($iface in Get-ChildItem $NbtBase) {
        if ($PSCmdlet.ShouldProcess($iface.PSChildName, 'NetbiosOptions=2 (disable)')) {
            Set-ItemProperty $iface.PSPath -Name 'NetbiosOptions' -Value 2 -Type DWord
        }
    }
}

if ($Rollback) {
    if ($PSCmdlet.ShouldProcess('LLMNR', 'Remove policy (OS default = enabled)')) {
        Remove-ItemProperty $LlmnrPath -Name 'EnableMulticast' -ErrorAction SilentlyContinue
    }
    foreach ($iface in Get-ChildItem $NbtBase) {
        if ($PSCmdlet.ShouldProcess($iface.PSChildName, 'NetbiosOptions=0 (DHCP default)')) {
            Set-ItemProperty $iface.PSPath -Name 'NetbiosOptions' -Value 0 -Type DWord
        }
    }
}

Get-State | Format-List
