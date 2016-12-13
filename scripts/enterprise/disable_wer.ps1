Write-Host "Disabling Windows Error Reporting (WER)" -ForegroundColor Cyan
$werKey = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
Set-ItemProperty $werKey -Name "ForceQueue" -Value 1

if(Test-Path "$werKey\Consent") {
    Set-ItemProperty "$werKey\Consent" -Name "DefaultConsent" -Value 1
}
Write-Host "Windows Error Reporting (WER) dialog has been disabled." -ForegroundColor Green  