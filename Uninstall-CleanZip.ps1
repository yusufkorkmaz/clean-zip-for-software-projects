[CmdletBinding(SupportsShouldProcess)]
param([string]$InstallationDirectory = (Join-Path $env:LOCALAPPDATA 'CleanZip'))

$ErrorActionPreference = 'Stop'
$engine = Join-Path ([IO.Path]::GetFullPath($InstallationDirectory)) 'CleanZip.exe'
$package = Get-AppxPackage -Name CleanZip.SoftwareProjects -ErrorAction SilentlyContinue
if ($package -and $package.InstallLocation.TrimEnd('\') -eq [IO.Path]::GetFullPath($InstallationDirectory).TrimEnd('\')) {
    if ($PSCmdlet.ShouldProcess($package.PackageFullName, 'Remove the modern Clean Zip context menu')) { Remove-AppxPackage -Package $package.PackageFullName }
}
foreach ($key in @('HKCU:\Software\Classes\Directory\shell\CleanZip', 'HKCU:\Software\Classes\Directory\Background\shell\CleanZip')) {
    $commandKey = Join-Path $key 'command'
    if (-not (Test-Path -LiteralPath $commandKey)) { continue }
    $command = (Get-Item -LiteralPath $commandKey).GetValue('')
    if (-not $command.StartsWith(('"' + $engine + '" '), [StringComparison]::OrdinalIgnoreCase)) { continue }
    if ($PSCmdlet.ShouldProcess($key, 'Remove the Clean Zip context menu')) { Remove-Item -LiteralPath $key -Recurse }
}
Write-Output 'Context-menu removal complete. Installed files and backups remain in the installation folder.'
