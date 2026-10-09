$ErrorActionPreference = 'Stop'
$installer = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\dist\CleanZip-Setup.exe'))
$target = Join-Path $env:LOCALAPPDATA ('CleanZip-CI-' + [Guid]::NewGuid().ToString('N'))
try {
    $process = Start-Process -FilePath $installer -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/DIR="' + $target + '"')) -PassThru -Wait -WindowStyle Hidden
    if ($process.ExitCode -ne 0) { throw "Installer failed: $($process.ExitCode)" }
    & (Join-Path $target 'CleanZip.exe') --version
    if ($LASTEXITCODE -ne 0) { throw 'Installed engine failed.' }
    foreach ($key in @('HKCU:\Software\Classes\Directory\shell\CleanZip','HKCU:\Software\Classes\Directory\Background\shell\CleanZip')) {
        $command = (Get-ItemProperty -LiteralPath ($key + '\command')).'(default)'
        if (-not $command.StartsWith('"' + $target + '\CleanZip.exe" --path "') -or -not $command.EndsWith('" --no-ui')) { throw "Invalid installed menu command: $command" }
        $hidden = (Get-Item -LiteralPath $key).GetValueNames() -contains 'LegacyDisable'
        $modern = Test-Path -LiteralPath (Join-Path $target 'modern-installed.txt')
        if ($hidden -ne $modern) { throw 'Installer left a duplicate or hidden fallback menu.' }
    }
    & (Join-Path $PSScriptRoot 'Test-CleanZip.ps1') -ScriptPath (Join-Path $target 'CleanZip.ps1')
    $rules = Join-Path $target 'CleanZip.rules.txt'
    [IO.File]::AppendAllText($rules,"`n# preserved user rule`nf:private-note.txt`n")
    $hash = (Get-FileHash -LiteralPath $rules).Hash
    # An update must recover stale visibility when the modern menu is unavailable.
    # Windows Server CI exercises this fallback migration; Windows 11 checks the
    # complementary hidden fallback when package registration succeeds.
    foreach ($key in @('HKCU:\Software\Classes\Directory\shell\CleanZip','HKCU:\Software\Classes\Directory\Background\shell\CleanZip')) {
        New-ItemProperty -LiteralPath $key -Name LegacyDisable -PropertyType String -Value '' -Force | Out-Null
    }
    $process = Start-Process -FilePath $installer -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/DIR="' + $target + '"')) -PassThru -Wait -WindowStyle Hidden
    if ($process.ExitCode -ne 0 -or (Get-FileHash -LiteralPath $rules).Hash -ne $hash) { throw 'Update failed to preserve exclusion rules.' }
    foreach ($key in @('HKCU:\Software\Classes\Directory\shell\CleanZip','HKCU:\Software\Classes\Directory\Background\shell\CleanZip')) {
        $hidden = (Get-Item -LiteralPath $key).GetValueNames() -contains 'LegacyDisable'
        $modern = Test-Path -LiteralPath (Join-Path $target 'modern-installed.txt')
        if ($hidden -ne $modern) { throw 'Update failed to restore the correct fallback visibility.' }
    }
    $uninstall = Start-Process -FilePath (Join-Path $target 'unins000.exe') -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -PassThru -Wait -WindowStyle Hidden
    if ($uninstall.ExitCode -ne 0) { throw 'Uninstaller failed.' }
    if (Test-Path 'HKCU:\Software\Classes\Directory\shell\CleanZip') { throw 'Uninstaller left the menu behind.' }
    if (-not [IO.File]::Exists($rules) -or (Get-FileHash -LiteralPath $rules).Hash -ne $hash) { throw 'Uninstaller removed user rules.' }
    Write-Output 'PASS: one-file setup, menu visibility migration, installed ZIP, silent update, preserved rules and uninstallation.'
} finally { }
