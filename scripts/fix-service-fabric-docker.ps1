Write-Host "Stopping Docker services"

$dfw = Get-Process "Docker for Windows" -ErrorAction SilentlyContinue
if ($dfw) {
    Stop-Process $dfw -Force
}

Stop-Service "com.docker.service"

$dd = Get-Process "dockerd" -ErrorAction SilentlyContinue
if ($dd) {
    Stop-Process $dd -Force
}

# Remove-Path "C:\Program Files\Docker\Docker\resources\bin"

Write-Host "Downloading Docker CE daemon"

$destPath = "C:\Program Files\Docker\DockerCE"
$zipPath = "$env:TEMP\docker-ce.zip"
(New-Object Net.WebClient).DownloadFile('https://download.docker.com/win/static/stable/x86_64/docker-17.09.0-ce.zip', $zipPath)
7z x $zipPath -o"$destPath" | Out-Null
del $zipPath

Add-Path "$destPath\docker"

Write-Host "Docker CE installed" -ForegroundColor Green
