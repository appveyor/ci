Write-Host "Installing Visual Studio 2015 Community..." -ForegroundColor Cyan
webpicmd /Install /Products:"VS2015_CE_Only" /AcceptEula /SuppressReboot
Add-Path 'C:\Program Files (x86)\MSBuild\14.0\Bin'
Add-Path 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE'
Add-Path 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow'
Write-Host "Visual Studio 2015 Community installed" -ForegroundColor Green
