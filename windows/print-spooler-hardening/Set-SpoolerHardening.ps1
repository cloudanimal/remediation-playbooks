<#
.SYNOPSIS
    Audit and harden the Windows Print Spooler (PrintNightmare-class exposure).
.DESCRIPTION
    -DisableService: stop and disable the spooler (DCs / non-printing servers).
    -RestrictPointAndPrint: keep printing but require admin for driver installs
     and block client connections, per Microsoft guidance for CVE-2021-34527.
.EXAMPLE
    .\Set-SpoolerHardening.ps1 -Audit
    .\Set-SpoolerHardening.ps1 -DisableService
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Audit,
    [switch]$DisableService,
    [switch]$RestrictPointAndPrint,
    [switch]$Rollback
)

$PnPPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$RpcPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers'

function Get-State {
    $svc = Get-Service -Name Spooler
    [PSCustomObject]@{
        SpoolerStatus      = $svc.Status
        SpoolerStartType   = $svc.StartType
        NoWarningNoElevate = (Get-ItemProperty $PnPPath -Name 'NoWarningNoElevationOnInstall' -ErrorAction SilentlyContinue).NoWarningNoElevationOnInstall
        UpdatePromptSettings = (Get-ItemProperty $PnPPath -Name 'UpdatePromptSettings' -ErrorAction SilentlyContinue).UpdatePromptSettings
        ClientConnectionsBlocked = (Get-ItemProperty $RpcPath -Name 'RegisterSpoolerRemoteRpcEndPoint' -ErrorAction SilentlyContinue).RegisterSpoolerRemoteRpcEndPoint
    }
}

if ($Audit -or (-not $DisableService -and -not $RestrictPointAndPrint -and -not $Rollback)) {
    $state = Get-State
    $state | Format-List
    $isDC = (Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4
    if ($isDC -and $state.SpoolerStatus -eq 'Running') {
        Write-Host 'NON-COMPLIANT: spooler running on a domain controller.' -ForegroundColor Red
        exit 1
    }
    Write-Host 'Review state against the decision tree in the README.' -ForegroundColor Cyan
    exit 0
}

if ($DisableService) {
    if ($PSCmdlet.ShouldProcess('Spooler', 'Stop and disable')) {
        Stop-Service Spooler -Force
        Set-Service Spooler -StartupType Disabled
    }
}

if ($RestrictPointAndPrint) {
    if (-not (Test-Path $PnPPath)) { New-Item $PnPPath -Force | Out-Null }
    if ($PSCmdlet.ShouldProcess('PointAndPrint', 'Restrict')) {
        # Require elevation warnings for driver install and update
        Set-ItemProperty $PnPPath -Name 'NoWarningNoElevationOnInstall' -Value 0 -Type DWord
        Set-ItemProperty $PnPPath -Name 'UpdatePromptSettings' -Value 0 -Type DWord
        # Block remote RPC clients (set 2 = disabled endpoint)
        Set-ItemProperty $RpcPath -Name 'RegisterSpoolerRemoteRpcEndPoint' -Value 2 -Type DWord
    }
}

if ($Rollback) {
    if ($PSCmdlet.ShouldProcess('Spooler', 'Re-enable service and remove policies')) {
        Set-Service Spooler -StartupType Automatic
        Start-Service Spooler
        Remove-ItemProperty $RpcPath -Name 'RegisterSpoolerRemoteRpcEndPoint' -ErrorAction SilentlyContinue
        if (Test-Path $PnPPath) { Remove-Item $PnPPath -Recurse }
    }
}

Get-State | Format-List
