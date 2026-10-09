[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'build' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (-not (Get-Command dotnet.exe -ErrorAction SilentlyContinue)) { throw 'Install the .NET 10 x64 SDK to build the modern menu.' }
& dotnet.exe build (Join-Path $PSScriptRoot 'modern\CleanZip.Shell.csproj') -c Release -o (Join-Path $OutputDirectory 'modern') --ignore-failed-sources
if ($LASTEXITCODE -ne 0) { throw 'Modern shell extension compilation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'modern\AppxManifest.xml') -Destination (Join-Path $OutputDirectory 'AppxManifest.xml') -Force
Add-Type -AssemblyName System.Drawing
$assets = Join-Path $OutputDirectory 'Assets'
New-Item -ItemType Directory -Path $assets -Force | Out-Null
foreach ($size in @(150,44,32)) {
    $bitmap = New-Object Drawing.Bitmap $size,$size
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([Drawing.Color]::Transparent)
    $blue = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(0,103,192))
    $gold = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255,192,46))
    $graphics.FillRectangle($blue,[int]($size*.15),[int]($size*.12),[int]($size*.7),[int]($size*.76))
    for ($i=0;$i -lt 6;$i++) { $graphics.FillRectangle($gold,[int]($size*.45),[int]($size*(.2+.08*$i)),[int]($size*.12),[int]($size*.045)) }
    if ($size -eq 150) { $bitmap.Save((Join-Path $assets 'Logo.png'),[Drawing.Imaging.ImageFormat]::Png) }
    elseif ($size -eq 44) { $bitmap.Save((Join-Path $assets 'SmallLogo.png'),[Drawing.Imaging.ImageFormat]::Png) }
    else {
        # A single PNG-compressed frame is a valid Vista-and-later ICO.
        $memory = New-Object IO.MemoryStream
        $bitmap.Save($memory,[Drawing.Imaging.ImageFormat]::Png)
        $bytes = $memory.ToArray()
        $file = [IO.File]::Create((Join-Path $assets 'CleanZip.ico'))
        $writer = New-Object IO.BinaryWriter $file
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]32); $writer.Write([byte]32); $writer.Write([uint16]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32); $writer.Write([uint32]$bytes.Length); $writer.Write([uint32]22); $writer.Write($bytes)
        $writer.Dispose(); $memory.Dispose()
    }
    $blue.Dispose(); $gold.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
Write-Output "Built modern menu: $OutputDirectory"
