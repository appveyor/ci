Write-Host "WinRM - allow * hosts" -ForegroundColor Cyan
cmd /c 'winrm set winrm/config/client @{TrustedHosts="*"}'
Write-Host "WinRM configured" -ForegroundColor Green