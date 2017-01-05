#Reason to create callme.ps1 file is to make script copy-paste-able to PS windows and still be able to ask for password

'Write-Warning "This script will overwrite current auto-logon settings if they exist"

$user = whoami
$securePwd = Read-Host "Please enter password for current user to be saved for auto-logon" -AsSecureString 

#http://stackoverflow.com/questions/21741803/powershell-securestring-encrypt-decrypt-to-plain-text-not-working
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
$pwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -PropertyType String -Value 1

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUsername -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUsername -PropertyType String -Value $user 

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -PropertyType String -Value $pwd

del .\callme.ps1' > callme.ps1

.\callme.ps1
