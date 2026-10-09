[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$InstallationDirectory = (Join-Path $env:LOCALAPPDATA 'CleanZip'),
    [switch]$RestoreWindows11Menu
)
$ErrorActionPreference = 'Stop'
$InstallationDirectory = [IO.Path]::GetFullPath($InstallationDirectory)
if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { throw 'This shell extension currently supports x64 Windows 11.' }
if ([int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber -lt 22000) { throw 'The modern menu requires Windows 11.' }
$developer = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
if ($developer.AllowDevelopmentWithoutDevLicense -ne 1) { throw 'This source-build registration requires Developer Mode. Enable it explicitly in Windows Settings, or use the legacy installer.' }
if (-not (Test-Path -LiteralPath (Join-Path $InstallationDirectory 'CleanZip.exe'))) { throw 'Install Clean Zip first with Install-CleanZip.ps1.' }
& dotnet.exe --list-runtimes | Out-String -OutVariable runtimes | Out-Null
if ($LASTEXITCODE -ne 0 -or $runtimes -notmatch 'Microsoft.NETCore.App 10\.') { throw 'The modern menu requires the .NET 10 x64 runtime.' }
if (-not $PSCmdlet.ShouldProcess($InstallationDirectory, 'Install and register the Windows 11 Clean Zip menu')) { return }
& (Join-Path $PSScriptRoot 'Build-ModernMenu.ps1')
$build = Join-Path $PSScriptRoot 'build'
$backup = Join-Path $InstallationDirectory ('backups\modern-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($name in @('Assets','AppxManifest.xml')) {
    $destination = Join-Path $InstallationDirectory $name
    if (Test-Path -LiteralPath $destination) { Copy-Item -LiteralPath $destination -Destination $backup -Recurse }
    Copy-Item -LiteralPath (Join-Path $build $name) -Destination $InstallationDirectory -Recurse -Force
}
# Loaded COM DLLs can remain locked. Use a new sibling directory for every installation.
$extensionName = 'modern-' + [Guid]::NewGuid().ToString('N')
Copy-Item -LiteralPath (Join-Path $build 'modern') -Destination (Join-Path $InstallationDirectory $extensionName) -Recurse
$manifestPath = Join-Path $InstallationDirectory 'AppxManifest.xml'
[xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
$namespaces = New-Object Xml.XmlNamespaceManager $manifest.NameTable
$namespaces.AddNamespace('com','http://schemas.microsoft.com/appx/manifest/com/windows10')
$manifest.SelectSingleNode('//com:Class',$namespaces).SetAttribute('Path',($extensionName + '\CleanZip.Shell.comhost.dll'))
$existingPackage = Get-AppxPackage -Name CleanZip.SoftwareProjects
if ($existingPackage) {
    $version = [version]$existingPackage.Version
    if ($version.Revision -ge 65535) { throw 'Package revision limit reached; increment the manifest version.' }
    $manifest.Package.Identity.Version = '{0}.{1}.{2}.{3}' -f $version.Major,$version.Minor,$version.Build,($version.Revision + 1)
}
$manifest.Save($manifestPath)
try { Add-AppxPackage -Register $manifestPath -ExternalLocation $InstallationDirectory }
catch {
    $previousManifest = Join-Path $backup 'AppxManifest.xml'
    if (Test-Path -LiteralPath $previousManifest) { Copy-Item -LiteralPath $previousManifest -Destination $manifestPath -Force }
    throw
}
if (-not (Get-AppxPackage -Name CleanZip.SoftwareProjects)) { throw 'Modern menu registration could not be verified.' }
if ($RestoreWindows11Menu) {
    $classic = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
    if (Test-Path -LiteralPath $classic) {
        & reg.exe export 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' (Join-Path $backup 'classic-menu.reg') /y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not back up the classic-menu override.' }
        Remove-Item -LiteralPath $classic -Recurse
    }
}
Write-Output 'Registered Clean Zip for the modern Windows 11 folder and folder-background menus.'
Write-Output "Backups: $backup"
Write-Output 'Restart File Explorer to reload the context menu registration.'
