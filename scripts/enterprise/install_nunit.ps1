Write-Host "Installing NUnit 2.6.4..." -ForegroundColor Cyan
$toolsPath = "$env:SYSTEMDRIVE\Tools"
$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit"

Remove-Item $nunitPath -Recurse -Force -ErrorAction SilentlyContinue

# nunit
$zipPath = "$($env:USERPROFILE)\NUnit-2.6.4.zip"
(New-Object Net.WebClient).DownloadFile('http://github.com/nunit/nunitv2/releases/download/2.6.4/NUnit-2.6.4.zip', $zipPath)
7z x $zipPath -y -o"$toolsPath" | Out-Null
del $zipPath
[IO.Directory]::Move("$toolsPath\NUnit-2.6.4", $nunitPath)

# logger
$zipPath = "$($env:USERPROFILE)\Appveyor.NUnitLogger.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.NUnitLogger.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\bin\addins" | Out-Null
del $zipPath

Add-Path "$nunitPath\bin"

Write-Host "NUnit installed" -ForegroundColor Green
