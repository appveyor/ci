Write-Host "Installing Visual Studio 2013 Community ..." -ForegroundColor Cyan
webpicmd /Install /Products:"VS2015_CE_Only" /AcceptEula /SuppressReboot
Add-Path "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
Write-Host "Visual Studio 2013 Community installed" -ForegroundColor Green
