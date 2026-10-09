param([string]$InstallationDirectory, [switch]$Remove)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($InstallationDirectory)
$log = Join-Path $root 'menu-install.log'
try {
    # No modern commands or dependency checks on older Windows.
    $build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
    if ($build -lt 22000) { exit 0 }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
    if ($arch -ne 'AMD64') { 'Classic menu: modern extension targets x64 Explorer.' | Out-File $log; exit 0 }
    if (-not (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)) { exit 0 }
    $packages = @(Get-AppxPackage -Name CleanZip.SoftwareProjects)
    if ($Remove) {
        foreach ($package in $packages) {
            # Remove only the package registered by this installation.
            if ([IO.File]::Exists((Join-Path $root 'modern-installed.txt')) -and $package.PackageFullName -eq ([IO.File]::ReadAllText((Join-Path $root 'modern-installed.txt'))).Trim()) {
                Remove-AppxPackage -Package $package.PackageFullName
            }
        }
        exit 0
    }
    $signed = Join-Path $root 'CleanZip.Identity.msix'
    if ([IO.File]::Exists($signed)) {
        # Production registration requires an identity package signed by a trusted publisher.
        Add-AppxPackage -Path $signed -ExternalLocation $root
    } else {
        $developer = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
        if (-not $developer -or $developer.AllowDevelopmentWithoutDevLicense -ne 1) {
            'Classic menu installed. A signed identity package or already-enabled Developer Mode is needed for the Windows 11 modern menu.' | Out-File $log
            exit 0
        }
        $manifestPath = Join-Path $root 'AppxManifest.xml'
        [xml]$manifest = [IO.File]::ReadAllText($manifestPath)
        $version = [Version]$manifest.Package.Identity.Version
        $registered = @($packages | Sort-Object Version -Descending | Select-Object -First 1)
        if ($registered.Count -and [Version]$registered[0].Version -ge $version) {
            $previous = [Version]$registered[0].Version
            $manifest.Package.Identity.SetAttribute('Version', ('{0}.{1}.{2}.{3}' -f $previous.Major,$previous.Minor,$previous.Build,($previous.Revision + 1)))
            $manifest.Save($manifestPath)
        }
        Add-AppxPackage -Register $manifestPath -ExternalLocation $root
    }
    $package = Get-AppxPackage -Name CleanZip.SoftwareProjects | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $package) { throw 'Modern package registration was not found.' }
    [IO.File]::WriteAllText((Join-Path $root 'modern-installed.txt'),$package.PackageFullName)
    'Modern menu installed; native C++ extension needs no .NET runtime.' | Out-File $log
    exit 0
} catch {
    # ZIP/classic functionality remains available if Windows rejects the optional identity registration.
    ('Classic menu installed. Modern menu registration: ' + $_.Exception.Message) | Out-File $log
    exit 1
}
