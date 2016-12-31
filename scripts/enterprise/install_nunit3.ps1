Write-Host "Installing NUnit 3.5.0..." -ForegroundColor Cyan -NoNewline
$toolsPath = "$env:SYSTEMDRIVE\Tools"
$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit3"

Remove-Item $nunitPath -Recurse -Force -ErrorAction SilentlyContinue

# nunit
$zipPath = "$($env:TEMP)\NUnit.3.5.0.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/nunit/nunit-console/releases/download/3.5/NUnit.Console-3.5.0.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath" | Out-Null
del $zipPath

# logger
$zipPath = "$($env:TEMP)\Appveyor.NUnit3Logger.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.NUnit3Logger.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\addins" | Out-Null
Move-Item "$nunitPath\addins\appveyor.addins" "$nunitPath\appveyor.addins"
del $zipPath

Remove-Path "$nunitPath\bin"
Add-Path "$nunitPath"

Write-Host "NUnit 3.5.0 installed" -ForegroundColor Green
