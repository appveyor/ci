Write-Host "Installing xUnit 1.9.2..." -ForegroundColor Cyan
$xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit"

Remove-Item $xunitPath -Recurse -Force -ErrorAction SilentlyContinue

$zipPath = "$($env:USERPROFILE)\xunit-build-1.9.2.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/xunit-build-1.9.2.zip', $zipPath)
7z x $zipPath -y -o"$xunitPath" | Out-Null
del $zipPath

Add-Path $xunitPath

Write-Host "xUnit 1.9.2 installed" -ForegroundColor Green
