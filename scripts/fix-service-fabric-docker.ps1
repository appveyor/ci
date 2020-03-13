Write-Host "Stopping Docker services"

$dfw = Get-Process "Docker for Windows" -ErrorAction SilentlyContinue
if ($dfw) {
    Stop-Process $dfw -Force
}

Stop-Service "com.docker.service" -ErrorAction SilentlyContinue

$dd = Get-Process "dockerd" -ErrorAction SilentlyContinue
if ($dd) {
    Stop-Process $dd -Force
}

Write-Host "Docker stopped" -ForegroundColor Green
