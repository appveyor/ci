Write-Host "Installing Visual Studio 2013 Community ..." -ForegroundColor Cyan
webpicmd /Install /Products:"VS2013_CE_Only" /AcceptEula /SuppressReboot
Add-Path "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
Add-Path 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE'
Write-Host "Visual Studio 2013 Community installed" -ForegroundColor Green
