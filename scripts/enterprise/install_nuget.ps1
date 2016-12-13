Write-Host "Installing NuGet..." -ForegroundColor Cyan

# nuget 3.x
Write-Host "NuGet 3.x"
$nuget3Path = "$env:SYSTEMDRIVE\Tools\NuGet"
if(-not (Test-Path $nuget3Path)) {
    New-Item $nuget3Path -ItemType Directory -Force | Out-Null
}

(New-Object Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/latest/nuget.exe', "$nuget3Path\nuget.exe")

Remove-Path $nuget2Path
Remove-Path $nuget3Path

# add default nuget configuration
$appDataNugetConfig = '<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://www.nuget.org/api/v2" />
  </packageSources>
</configuration>
'
$configDirectory = "$env:APPDATA\NuGet"
if(-not (Test-Path $configDirectory)) {
    New-Item $configDirectory -ItemType Directory -Force | Out-Null
}
Set-Content "$configDirectory\NuGet.config" -Value $appDataNugetConfig

Add-Path $nuget3Path
Add-SessionPath $nuget3Path    

Write-Host "NuGet installed" -ForegroundColor Green