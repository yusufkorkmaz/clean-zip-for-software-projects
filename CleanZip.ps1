param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [switch]$NoUI
)
$ErrorActionPreference = 'Stop'
$engine = Join-Path $PSScriptRoot 'CleanZip.exe'
if (-not (Test-Path -LiteralPath $engine)) { throw 'CleanZip.exe is missing. Run Install-CleanZip.ps1.' }
$engineArguments = @('--path', $Path, '--no-ui')
& $engine @engineArguments
if ($LASTEXITCODE -ne 0) { throw "Clean Zip failed: exit code $LASTEXITCODE" }
