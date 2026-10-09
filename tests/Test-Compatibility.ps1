#requires -Version 3.0
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\CleanZip.Installation.ps1')
$count = 0
foreach ($build in @(7601,9200,9600,10240,19045,21999)) {
    foreach ($architecture in @('AMD64','x86')) {
        $plan = Get-CleanZipMenuPlan -BuildNumber $build -Architecture $architecture
        if ($plan.Mode -ne 'Classic') { throw "Legacy Windows build $build must use the classic menu." }
        $count++
    }
}
foreach ($build in @(22000,22631,26100,26200)) {
    if ((Get-CleanZipMenuPlan -BuildNumber $build -Architecture AMD64).Mode -ne 'Modern') { throw "Modern selection failed: $build" }
    foreach ($architecture in @('x86','ARM64')) {
        if ((Get-CleanZipMenuPlan -BuildNumber $build -Architecture $architecture).Mode -ne 'Classic') { throw 'Unsupported architecture must retain the classic menu.' }
        $count++
    }
    if ((Get-CleanZipMenuPlan -BuildNumber $build -Architecture AMD64 -ModernUnavailableReason 'No .NET SDK').Mode -ne 'Classic') { throw 'Missing modern prerequisites must fall back to classic.' }
    if ((Get-CleanZipMenuPlan -RequestedMenu Classic -BuildNumber $build -Architecture AMD64).Mode -ne 'Classic') { throw 'Explicit classic selection failed.' }
    $count += 3
}
foreach ($arguments in @(
    @{RequestedMenu='Modern';BuildNumber=7601;Architecture='AMD64'},
    @{RequestedMenu='Modern';BuildNumber=19045;Architecture='AMD64'},
    @{RequestedMenu='Modern';BuildNumber=26200;Architecture='x86'},
    @{RequestedMenu='Modern';BuildNumber=26200;Architecture='AMD64';ModernUnavailableReason='No Developer Mode'}
)) {
    $rejected = $false
    try { Get-CleanZipMenuPlan @arguments | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Explicit modern mode must reject unavailable requirements.' }
    $count++
}

# Exercise the full detector as Windows 7/8/10, and fail if it ever probes modern dependencies.
function Get-ItemProperty {
    param([string]$LiteralPath)
    if ($LiteralPath -eq 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion') { return [pscustomobject]@{CurrentBuildNumber=$script:mockBuild} }
    throw "Legacy detector probed a modern registry setting: $LiteralPath"
}
function Get-Command { throw 'Legacy detector probed modern commands.' }
try {
    foreach ($build in @(7601,9200,9600,19045)) {
        $script:mockBuild = $build
        if ((Get-CleanZipContextMenuPlan).Mode -ne 'Classic') { throw 'Full legacy detector failed.' }
        $count++
    }
} finally { Remove-Item Function:\Get-ItemProperty; Remove-Item Function:\Get-Command }

# Emulate a Windows edition without Appx cmdlets during uninstallation.
function Get-Command {
    param([string]$Name)
    if ($Name -in @('Get-AppxPackage','Remove-AppxPackage')) { return }
    return Microsoft.PowerShell.Core\Get-Command -Name $Name
}
function Get-AppxPackage { throw 'The uninstaller attempted a missing Windows 7 cmdlet.' }
try { & (Join-Path $PSScriptRoot '..\Uninstall-CleanZip.ps1') -InstallationDirectory (Join-Path $PSScriptRoot '..\build\uninstalled-test') -WhatIf }
finally { Remove-Item Function:\Get-Command; Remove-Item Function:\Get-AppxPackage }

$file = Join-Path $PSScriptRoot '..\build\compatibility-hash.txt'
[IO.File]::WriteAllText($file,'abc')
if ((Get-CleanZipFileHash -Path $file) -ne 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD') { throw 'PowerShell 3.0-compatible SHA256 failed.' }
$name = [Reflection.AssemblyName]::GetAssemblyName((Join-Path $PSScriptRoot '..\build\CleanZip.exe'))
if ($name.ProcessorArchitecture -ne 'MSIL') { throw 'The legacy engine must support both x86 and x64.' }
Write-Output "PASS: $count menu compatibility cases; old-Windows dependency isolation, missing Appx cmdlets, SHA256 and AnyCPU engine verified."
