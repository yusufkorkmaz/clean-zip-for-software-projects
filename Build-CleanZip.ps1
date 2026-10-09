param([ValidateSet('x64','x86')][string]$Platform='x64')
$ErrorActionPreference = 'Stop'
$arch = if ($Platform -eq 'x86') { 'Win32' } else { 'x64' }
$output = Join-Path $PSScriptRoot "build\$Platform"
& cmake -S $PSScriptRoot -B $output -A $arch
if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed; install Visual Studio C++ tools and CMake.' }
& cmake --build $output --config Release --parallel
if ($LASTEXITCODE -ne 0) { throw 'Native C++ build failed.' }
foreach ($file in @('CleanZip.rules.txt','CleanZip.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $output 'Release') -Force
}
Write-Output "Built native Clean Zip: $output\Release"
