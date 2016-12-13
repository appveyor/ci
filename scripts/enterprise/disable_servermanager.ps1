Write-Host "Disabling Server Manager auto-start" -ForegroundColor Cyan
$serverManagerMachineKey = "HKLM:\SOFTWARE\Microsoft\ServerManager"
$serverManagerUserKey = "HKCU:\SOFTWARE\Microsoft\ServerManager"
if(Test-Path $serverManagerMachineKey) {
    Set-ItemProperty -Path $serverManagerMachineKey -Name "DoNotOpenServerManagerAtLogon" -Value 1
    Write-Host "Disabled Server Manager at logon for all users" -ForegroundColor Green
}
if(Test-Path $serverManagerUserKey) {
    Set-ItemProperty -Path $serverManagerUserKey -Name "CheckedUnattendLaunchSetting" -Value 0
    Write-Host "Disabled Server Manager for current user" -ForegroundColor Green
}

# disable scheduled task
schtasks /Change /TN "\Microsoft\Windows\Server Manager\ServerManager" /DISABLE