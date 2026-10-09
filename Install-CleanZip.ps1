[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$InstallationDirectory = (Join-Path $env:LOCALAPPDATA 'CleanZip'),
    [switch]$ResetRules
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Clean Zip requires Windows.' }
$InstallationDirectory = [IO.Path]::GetFullPath($InstallationDirectory)
if (-not $PSCmdlet.ShouldProcess($InstallationDirectory, 'Install Clean Zip and register the current-user context menu')) { return }
& (Join-Path $PSScriptRoot 'Build-CleanZip.ps1')
$buildDirectory = Join-Path $PSScriptRoot 'build'
if ($InstallationDirectory.TrimEnd('\') -eq $buildDirectory.TrimEnd('\')) { throw 'Choose an installation folder outside the build directory.' }
New-Item -ItemType Directory -Path $InstallationDirectory -Force | Out-Null
$backupDirectory = Join-Path $InstallationDirectory ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
$keys = @(
    @{ PS='HKCU:\Software\Classes\Directory\shell\CleanZip'; Native='HKCU\Software\Classes\Directory\shell\CleanZip'; Argument='%1'; Backup='directory.reg' },
    @{ PS='HKCU:\Software\Classes\Directory\Background\shell\CleanZip'; Native='HKCU\Software\Classes\Directory\Background\shell\CleanZip'; Argument='%V'; Backup='background.reg' }
)
foreach ($key in $keys) {
    if (Test-Path -LiteralPath $key.PS) {
        & reg.exe export $key.Native (Join-Path $backupDirectory $key.Backup) /y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not back up the existing context menu.' }
    }
}
foreach ($name in @('CleanZip.exe', 'CleanZip.ps1', 'CleanZip.rules.txt')) {
    $destination = Join-Path $InstallationDirectory $name
    if (Test-Path -LiteralPath $destination) { Copy-Item -LiteralPath $destination -Destination (Join-Path $backupDirectory $name) }
    if ($name -eq 'CleanZip.rules.txt' -and (Test-Path -LiteralPath $destination) -and -not $ResetRules) { continue }
    $staged = Join-Path $InstallationDirectory ($name + '.' + [Guid]::NewGuid().ToString('N') + '.new')
    Copy-Item -LiteralPath (Join-Path $buildDirectory $name) -Destination $staged
    if ($name -eq 'CleanZip.exe' -and (Test-Path -LiteralPath $destination)) {
        # Rename the old executable so a running ZIP operation can finish.
        $previous = Join-Path $backupDirectory 'CleanZip.running.exe'
        Move-Item -LiteralPath $destination -Destination $previous
        try { Move-Item -LiteralPath $staged -Destination $destination }
        catch { Copy-Item -LiteralPath $previous -Destination $destination; throw }
    } else { Move-Item -LiteralPath $staged -Destination $destination -Force }
    if ((Get-FileHash -LiteralPath (Join-Path $buildDirectory $name)).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) { throw "Installed file mismatch: $name" }
}
$engine = Join-Path $InstallationDirectory 'CleanZip.exe'
foreach ($key in $keys) {
    New-Item -Path $key.PS -Force | Out-Null
    Set-Item -LiteralPath $key.PS -Value 'Clean Zip'
    New-ItemProperty -LiteralPath $key.PS -Name Icon -Value $engine -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $key.PS -Name MultiSelectModel -Value Single -PropertyType String -Force | Out-Null
    $commandKey = Join-Path $key.PS 'command'
    New-Item -Path $commandKey -Force | Out-Null
    $command = '"{0}" --path "{1}" --no-ui' -f $engine,$key.Argument
    Set-Item -LiteralPath $commandKey -Value $command
    if ((Get-Item -LiteralPath $commandKey).GetValue('') -ne $command) { throw 'Context-menu verification failed.' }
}
Write-Output "Installed: $InstallationDirectory"
Write-Output "Backups: $backupDirectory"
Write-Output 'Right-click a folder or its background and select Clean Zip.'
