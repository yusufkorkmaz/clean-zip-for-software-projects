param([ValidateSet('x64','x86')][string]$Platform='x64')
$ErrorActionPreference = 'Stop'
$build = Join-Path $PSScriptRoot "..\build\$Platform\Release"
& (Join-Path $PSScriptRoot 'Test-CleanZip.ps1') -ScriptPath (Join-Path $build 'CleanZip.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Archive fixture failed.' }
foreach ($name in @('CleanZip.exe','CleanZip.Shell.dll')) {
    $bytes = [IO.File]::ReadAllBytes((Join-Path $build $name))
    $pe = [BitConverter]::ToInt32($bytes,0x3c)
    $optional = $pe + 24
    $directories = if ([BitConverter]::ToUInt16($bytes,$optional) -eq 0x20b) { $optional + 112 } else { $optional + 96 }
    if ([BitConverter]::ToUInt32($bytes,$directories + 14*8) -ne 0) { throw "$name depends on the CLR/.NET runtime." }
}
$fixture = Join-Path $PSScriptRoot "..\build\shell-$Platform"
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $fixture 'source.ts'),'fixture')
& (Join-Path $build 'ShellTests.exe') (Join-Path $build 'CleanZip.Shell.dll') ([IO.Path]::GetFullPath($fixture)) ([IO.Path]::GetFullPath((Join-Path $fixture 'source.ts')))
if ($LASTEXITCODE -ne 0) { throw 'Native COM shell test failed.' }
# Built-in ZIP writer must preserve the previous output on error and reject output in the project.
$engine = Join-Path $build 'CleanZip.exe'
$output = "$fixture.zip"
& $engine --path $fixture --output $output --no-ui
if ($LASTEXITCODE -ne 0) { throw 'First ZIP failed.' }
$hash = (Get-FileHash -LiteralPath $output).Hash
& $engine --path $fixture --output (Join-Path $fixture 'inside.zip') --no-ui
if ($LASTEXITCODE -eq 0 -or [IO.File]::Exists((Join-Path $fixture 'inside.zip'))) { throw 'Source-directory output must be rejected.' }
& $engine --path (Join-Path $fixture 'missing') --output $output --no-ui
if ($LASTEXITCODE -eq 0 -or (Get-FileHash -LiteralPath $output).Hash -ne $hash) { throw 'Failed run damaged the previous ZIP.' }
Write-Output "PASS: $Platform executables are native, archive exclusions and failure preservation verified."
# Reset exit code after intentional rejected invocations.
$global:LASTEXITCODE = 0
