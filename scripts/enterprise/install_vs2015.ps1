Write-Host "Installing Visual Studio 2015 Community..." -ForegroundColor Cyan
webpicmd /Install /Products:"VS2015CommunityAzurePack.2.9" /AcceptEula /SuppressReboot
Add-Path 'C:\Program Files (x86)\MSBuild\14.0\Bin'
Write-Host "Visual Studio 2015 Community installed" -ForegroundColor Green
