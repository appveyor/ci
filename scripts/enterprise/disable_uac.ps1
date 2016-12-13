Write-Host "Disabling UAC" -ForegroundColor Cyan

Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "0"

Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green  