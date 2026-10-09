#requires -Version 3.0

function Get-CleanZipFileHash {
    param([Parameter(Mandatory = $true)][string]$Path)
    # Get-FileHash was introduced in PowerShell 4.0; use the framework API for PowerShell 3.0.
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Get-CleanZipMenuPlan {
    param(
        [ValidateSet('Auto','Classic','Modern')][string]$RequestedMenu = 'Auto',
        [int]$BuildNumber,
        [string]$Architecture,
        [string]$ModernUnavailableReason = ''
    )
    if ($RequestedMenu -eq 'Classic') { return [pscustomobject]@{ Mode='Classic'; Reason='Classic menu explicitly selected.' } }
    $reason = ''
    if ($BuildNumber -lt 22000) { $reason = 'This Windows version uses the classic context menu.' }
    elseif ($Architecture -ne 'AMD64') { $reason = 'The modern extension requires x64 Windows and an x64 PowerShell process.' }
    elseif ($ModernUnavailableReason) { $reason = $ModernUnavailableReason }
    if ($reason) {
        if ($RequestedMenu -eq 'Modern') { throw $reason }
        return [pscustomobject]@{ Mode='Classic'; Reason=$reason }
    }
    return [pscustomobject]@{ Mode='Modern'; Reason='Windows 11 modern-menu requirements are available.' }
}

function Get-CleanZipContextMenuPlan {
    param([ValidateSet('Auto','Classic','Modern')][string]$RequestedMenu = 'Auto')
    $build = [int](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { $architecture = 'ARM64' }
    # Return before probing Appx, Developer Mode or dotnet on older Windows or in classic mode.
    if ($RequestedMenu -eq 'Classic' -or $build -lt 22000 -or $architecture -ne 'AMD64') {
        return Get-CleanZipMenuPlan -RequestedMenu $RequestedMenu -BuildNumber $build -Architecture $architecture
    }
    $missing = @()
    if (-not (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) -or -not (Get-Command Add-AppxPackage -ErrorAction SilentlyContinue)) {
        $missing += 'Windows package-registration commands'
    }
    $developer = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
    if (-not $developer -or $developer.AllowDevelopmentWithoutDevLicense -ne 1) { $missing += 'Developer Mode' }
    $dotnet = Get-Command dotnet.exe -ErrorAction SilentlyContinue
    if (-not $dotnet) { $missing += '.NET 10 x64 SDK and runtime' }
    else {
        $sdks = (& $dotnet.Source --list-sdks 2>$null) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $sdks -notmatch '(?m)^10\.') { $missing += '.NET 10 x64 SDK' }
        $runtimes = (& $dotnet.Source --list-runtimes 2>$null) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $runtimes -notmatch '(?m)^Microsoft.NETCore.App 10\.') { $missing += '.NET 10 x64 runtime' }
    }
    $reason = ''
    if ($missing.Count) { $reason = 'Modern menu unavailable: ' + ($missing -join ', ') + '.' }
    return Get-CleanZipMenuPlan -RequestedMenu $RequestedMenu -BuildNumber $build -Architecture $architecture -ModernUnavailableReason $reason
}
