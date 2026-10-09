#requires -Version 3.0
[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [ValidateSet('AnyCPU','x86','x64')][string]$Platform = 'AnyCPU'
)

$ErrorActionPreference = 'Stop'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'build' }
if ($env:OS -ne 'Windows_NT') { throw 'Clean Zip requires Windows.' }
$framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
if (-not (Test-Path -LiteralPath (Join-Path $framework 'csc.exe'))) {
    $framework = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319'
}
$compiler = Join-Path $framework 'csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler not found.' }
foreach ($assembly in @('System.IO.Compression.dll','System.IO.Compression.FileSystem.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $framework $assembly))) { throw 'Clean Zip requires .NET Framework 4.5 or later, including its ZIP assemblies.' }
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$engine = Join-Path $OutputDirectory 'CleanZip.exe'
& $compiler /nologo /optimize+ /target:exe "/platform:$Platform" "/out:$engine" "/reference:$(Join-Path $framework 'System.IO.Compression.dll')" "/reference:$(Join-Path $framework 'System.IO.Compression.FileSystem.dll')" /reference:System.Windows.Forms.dll (Join-Path $PSScriptRoot 'CleanZip.cs')
if ($LASTEXITCODE -ne 0) { throw 'C# compilation failed.' }
foreach ($name in @('CleanZip.ps1', 'CleanZip.rules.txt')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $OutputDirectory $name) -Force
}
Write-Output "Built: $engine"
