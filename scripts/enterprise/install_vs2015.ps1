Write-Host "Installing Visual Studio 2015 Community..." -ForegroundColor Cyan

$vs14Path = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE"

if(-not (Test-Path $vs14Path)) {
    webpicmd /Install /Products:"VS2015_CE_Only" /AcceptEula /SuppressReboot
}

Add-Path "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin"
Add-Path $vs14Path
Add-Path "$vs14Path\IDE\CommonExtensions\Microsoft\TestWindow"

Write-Host "Visual Studio 2015 Community installed" -ForegroundColor Green
