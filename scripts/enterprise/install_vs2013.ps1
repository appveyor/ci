Write-Host "Installing Visual Studio 2013 Community ..." -ForegroundColor Cyan

$vs12Path = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE"

if(-not (Test-Path $vs12Path)) {
    webpicmd /Install /Products:"VS2013_CE_Only" /AcceptEula /SuppressReboot
}

Add-Path "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
Add-Path $vs12Path
Add-Path "$vs12Path\CommonExtensions\Microsoft\TestWindow"

Write-Host "Visual Studio 2013 Community installed" -ForegroundColor Green
