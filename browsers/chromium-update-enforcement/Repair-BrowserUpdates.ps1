<#
.SYNOPSIS
    Audit and repair Chrome/Edge auto-update plumbing.
.DESCRIPTION
    Perpetually outdated browsers are almost always broken update services or
    blocking policies, not missed patches. -Repair re-enables update services,
    clears update-blocking registry policies, and triggers an update check.
.EXAMPLE
    .\Repair-BrowserUpdates.ps1 -Audit
    .\Repair-BrowserUpdates.ps1 -Repair
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$Repair
)

$UpdateServices = 'gupdate', 'gupdatem', 'edgeupdate', 'edgeupdatem'
$PolicyPaths = @(
    'HKLM:\SOFTWARE\Policies\Google\Update',
    'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
)
$BlockingValues = 'UpdateDefault', 'DisableAutoUpdateChecksCheckboxValue', 'AutoUpdateCheckPeriodMinutes'

function Get-BrowserVersions {
    $apps = @(
        @{ Name = 'Chrome'; Path = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" },
        @{ Name = 'Edge';   Path = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe" }
    )
    foreach ($app in $apps) {
        if (Test-Path $app.Path) {
            [PSCustomObject]@{
                Browser = $app.Name
                Version = (Get-Item $app.Path).VersionInfo.ProductVersion
            }
        }
    }
}

function Get-UpdateHealth {
    foreach ($name in $UpdateServices) {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc) {
            [PSCustomObject]@{
                Service   = $name
                StartType = $svc.StartType
                Status    = $svc.Status
                Healthy   = $svc.StartType -ne 'Disabled'
            }
        }
    }
}

function Get-BlockingPolicies {
    foreach ($path in $PolicyPaths) {
        if (-not (Test-Path $path)) { continue }
        $props = Get-ItemProperty $path
        foreach ($value in $BlockingValues) {
            if ($null -ne $props.$value) {
                [PSCustomObject]@{ Path = $path; Name = $value; Value = $props.$value }
            }
        }
        # Version pins (Chrome: TargetVersionPrefix; Edge: TargetVersion)
        foreach ($pin in 'TargetVersionPrefix', 'TargetVersion') {
            if ($null -ne $props.$pin) {
                [PSCustomObject]@{ Path = $path; Name = $pin; Value = $props.$pin }
            }
        }
    }
}

Write-Host "Installed browsers:" -ForegroundColor Cyan
Get-BrowserVersions | Format-Table -AutoSize
Write-Host "Update services:" -ForegroundColor Cyan
Get-UpdateHealth | Format-Table -AutoSize
$blocking = Get-BlockingPolicies
if ($blocking) {
    Write-Host "Update-blocking policies found:" -ForegroundColor Yellow
    $blocking | Format-Table -AutoSize
}

if ($Audit -or -not $Repair) {
    $broken = (Get-UpdateHealth | Where-Object { -not $_.Healthy })
    if ($broken -or $blocking) {
        Write-Host 'NON-COMPLIANT: update plumbing is broken or blocked.' -ForegroundColor Yellow
        exit 1
    }
    Write-Host 'COMPLIANT: update services healthy, no blocking policies.' -ForegroundColor Green
    exit 0
}

# --- Repair ---
foreach ($svc in Get-UpdateHealth | Where-Object { -not $_.Healthy }) {
    if ($PSCmdlet.ShouldProcess($svc.Service, 'Set StartType=Manual')) {
        Set-Service -Name $svc.Service -StartupType Manual
    }
}
foreach ($policy in $blocking) {
    if ($PSCmdlet.ShouldProcess("$($policy.Path)\$($policy.Name)", 'Remove blocking policy')) {
        Remove-ItemProperty -Path $policy.Path -Name $policy.Name
    }
}

# Trigger immediate update checks where the updater exists
$updaters = @(
    "$env:ProgramFiles\Google\Update\GoogleUpdate.exe",
    "${env:ProgramFiles(x86)}\Google\Update\GoogleUpdate.exe",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
)
foreach ($exe in $updaters | Where-Object { Test-Path $_ }) {
    if ($PSCmdlet.ShouldProcess($exe, 'Trigger update check')) {
        Start-Process $exe -ArgumentList '/ua /installsource scheduler' -NoNewWindow
    }
}
Write-Host 'Repair complete. Re-audit in ~10 minutes once updates download.' -ForegroundColor Cyan
