Write-Host "Installing NUnit 3.2.0..." -ForegroundColor Cyan
$toolsPath = "$env:SYSTEMDRIVE\Tools"
$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit3"

Remove-Item $nunitPath -Recurse -Force

# nunit
$zipPath = "$($env:TEMP)\NUnit-3.2.0.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/nunit/nunit/releases/download/3.2.0/NUnit-3.2.0.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath" | Out-Null
del $zipPath

# logger
$zipPath = "$($env:TEMP)\Appveyor.NUnit3Logger.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.NUnit3ResultWriter.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\bin\addins" | Out-Null
Move-Item "$nunitPath\bin\addins\appveyor.addins" "$nunitPath\bin\appveyor.addins"
del $zipPath

Add-Path "$nunitPath\bin"

Write-Host "NUnit 3 installed" -ForegroundColor Green
