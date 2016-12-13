$webPIFolder = "$env:ProgramFiles\Microsoft\Web Platform Installer"
if([IO.File]::Exists("$webPIFolder\webpicmd.exe")) {
    Add-SessionPath $webPIFolder
    Write-Host "Web PI is already installed" -ForegroundColor Green
    return
}

Write-Host "Installing Web Platform Installer (Web PI)..." -ForegroundColor Cyan

# http://www.iis.net/learn/install/web-platform-installer/web-platform-installer-direct-downloads
$msiPath = "$env:USERPROFILE\WebPlatformInstaller_amd64_en-US.msi"
(New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi', $msiPath)

cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath
Add-SessionPath $webPIFolder
Write-Host "Web PI installed" -ForegroundColor Green