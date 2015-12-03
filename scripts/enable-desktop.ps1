if(-not $screen_resolution) {
  $screen_resolution = '1024x768'
}

# https://github.com/FreeRDP/FreeRDP/wiki/CommandLineInterface
Write-Host "Setting up active Desktop..." -ForegroundColor cyan
$zipPath = "$($env:USERPROFILE)\wfreerdp-1.1.zip"
(New-Object Net.WebClient).DownloadFile('http://av1southus4workers.blob.core.windows.net/downloads/tools/wfreerdp-1.1.zip', $zipPath)
7z x $zipPath -y -o"$env:appveyor_build_folder" | Out-Null

Write-Host "Starting Remote Desktop session..."
$psw = (get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -name DefaultPassword).DefaultPassword
Start-Process "$env:appveyor_build_folder\wfreerdp.exe" -ArgumentList '/v:127.0.0.1','/u:appveyor',"/p:$psw","/size:$screen_resolution" -WindowStyle Hidden

Write-Host "Waiting for RDP to connect..."
Start-Sleep -s 5

Write-Host "Desktop ready"-ForegroundColor green
