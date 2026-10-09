param([string]$ScriptPath = (Join-Path $PSScriptRoot '..\build\CleanZip.ps1'))
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$fixture = Join-Path $PSScriptRoot ('..\build\tests-' + [Guid]::NewGuid().ToString('N') + '\sample project [2]')
$include = @('package.json', 'package-lock.json', 'src\page.tsx', 'backend\App.cs', 'backend\App.csproj', '.env.example', 'src\binance\index.ts', 'src\object\index.ts', 'next.config.js', 'src\@test.ts', 'src\a ! b.ts', 'src\sayfa [1].tsx', ('src\T' + [char]0xFC + 'rk' + [char]0xE7 + 'e.ts'))
$include += @('src\app.js', 'src\styles.css', 'src\NORMAL.JS', 'src\NORMAL.CSS', 'src\minify.js', 'src\app.min.js.ts', 'docs\manual.docx.md', 'schema.sql', 'config.json', 'data.csv')
$exclude = @('node_modules\lib\index.js', '.next\server\page.js', 'frontend\.next\cache\data', 'backend\obj\project.assets.json', 'backend\bin\Release\App.dll', 'backend\nested\OBJ\data', 'frontend\NODE_MODULES\lib.js', '.git\config', 'dist\app.js', 'nested\photo.JPG', 'nested\report.PDF', 'nested\movie.MP4', 'nested\image.png', 'nested\image.jpeg', 'nested\image.webp', 'nested\image.avif', 'nested\image.gif', 'nested\movie.mkv', 'nested\movie.mov', 'nested\movie.webm', 'nested\sound.wav', 'nested\sound.mp3', 'nested\sound.flac')
foreach ($extension in @('dll', 'exe', 'pdb', 'lib', 'so', 'so.1', 'dylib', 'a', 'o', 'obj', 'class', 'pyc', 'pyo', 'jar', 'war', 'ear')) {
  $exclude += "assembly.$extension"
  $exclude += "backend\references\assembly.$($extension.ToUpperInvariant())"
}
$exclude += 'backend\nested\BIN\source.cs'
$exclude += 'frontend\nested\DIST\source.ts'
$exclude += '.tmp-runtime\sec\tool.json'
$exclude += 'frontend\.mock-media\archive.json'
foreach ($extension in @('zip', '7z', 'rar', 'tar', 'gz', 'tgz', 'bin', 'woff', 'woff2', 'ttf', 'map', 'tsbuildinfo')) {
  $exclude += "nested\asset.$extension"
}
foreach ($extension in @('pptx', 'ppt', 'ppsx', 'odp', 'docx', 'doc', 'xlsx', 'xls', 'odt', 'ods', 'psd', 'ai', 'xd', 'sketch', 'msi', 'msix', 'iso', 'img', 'dmg', 'vhdx', 'mdf', 'ldf', 'sqlite', 'db', 'dump', 'onnx', 'pt', 'pth', 'safetensors', 'temp', 'swp', 'swo', 'dmp')) {
  $exclude += "document.$extension"
  $exclude += "nested\DOCUMENT.$($extension.ToUpperInvariant())"
}
$exclude += @('app.min.js', 'app.min.css', 'nested\APP.MIN.JS', 'nested\APP.MIN.CSS')
foreach ($relative in @($include) + @($exclude)) {
  $filePath = Join-Path $fixture $relative
  New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($filePath)) -Force | Out-Null
  if ([IO.File]::Exists($filePath)) { [IO.File]::SetAttributes($filePath, [IO.FileAttributes]::Normal) }
  [IO.File]::WriteAllText($filePath, 'fixture')
}
# Also confirm that a hidden file is retained.
$hiddenPath = Join-Path $fixture '.env.example'
[IO.File]::SetAttributes($hiddenPath, [IO.FileAttributes]::Hidden)
& $scriptPath -Path $fixture -NoUI
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = "$fixture.zip"
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $actual = @($zip.Entries | ForEach-Object { $_.FullName })
  $expected = @($include | ForEach-Object { $_.Replace('\', '/') })
  $diff = @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual)
  if ($diff.Count -gt 0) { throw ($diff | Out-String) }
  foreach ($entry in $zip.Entries) {
    $reader = New-Object IO.StreamReader($entry.Open())
    try { if ($reader.ReadToEnd() -ne 'fixture') { throw "Content mismatch: $($entry.FullName)" } }
    finally { $reader.Dispose() }
  }
  Write-Output "PASS: $($actual.Count) source files included, $($exclude.Count) excluded paths absent; spaces, brackets, hidden files, nested folders and uppercase extensions verified."
}
finally { $zip.Dispose() }
