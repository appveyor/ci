Write-Host "Installing Visual Studio 2013 Community ..." -ForegroundColor Cyan
Add-Path "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
webpicmd /Install /Products:"VS2015_CE_Only" /AcceptEula /SuppressReboot
Write-Host "Visual Studio 2013 Community installed" -ForegroundColor Green
