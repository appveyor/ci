# installing with Web PI
Write-Host "Installing Visual Studio 2015 Community..." -ForegroundColor Cyan
cmd /c start /wait webpicmd /Install /Products:"VS2015CommunityAzurePack.2.9" /AcceptEula /SuppressReboot
Write-Host "Visual Studio 2015 Community installed" -ForegroundColor Green

# add msbuild to path
Add-Path 'C:\Program Files (x86)\MSBuild\14.0\Bin'