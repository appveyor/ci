Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
$exePath = "$env:USERPROFILE\7z1604-x64.exe"
Invoke-WebRequest http://www.7-zip.org/a/7z1604-x64.exe -OutFile $exePath
cmd /c start /wait $exePath /S
del $exePath

$sevenZipFolder = 'C:\Program Files\7-Zip'
Add-SessionPath $sevenZipFolder
Add-Path "$sevenZipFolder"

Write-Host "7-Zip installed" -ForegroundColor Green