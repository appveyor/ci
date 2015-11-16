# Enable SSL3
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

# get current IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like '*ethernet*'}).IPAddress
$port = 3389

if($ip.StartsWith('192.168.') -or $ip.StartsWith('10.240.')) {
    # new environment - behind NAT
    $port = 33800 + $ip.split('.')[3]
    $password = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", '')
} else {
    # generate password
    $randomObj = New-Object System.Random
    $password = ""
    1..12 | ForEach { $password = $password + [char]$randomObj.next(33,126) }

    # change password
    $objUser = [ADSI]("WinNT://$($env:computername)/appveyor")
    $objUser.SetPassword($password)   
}

# get external IP
$wc = (New-Object Net.WebClient)
$wc.Headers.Add("User-Agent", "AppVeyor")
$ip = $wc.DownloadString('https://canhazip.com/').Trim()

# allow RDP on firewall
Enable-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-in)'

Write-Host "Remote Desktop connection details:" -ForegroundColor Yellow
Write-Host "  Server: $ip`:$port" -ForegroundColor Gray
Write-Host "  Username: appveyor" -ForegroundColor Gray
Write-Host "  Password: $password" -ForegroundColor Gray

if($blockRdp) {
    # place "lock" file
    $path = "$($env:USERPROFILE)\Desktop\Delete me to continue build.txt"
    Set-Content -Path $path -Value ''    
    Write-Warning "There is 'Delete me to continue build.txt' file has been created on Desktop - delete it to continue the build."

    while($true) { if (-not (Test-Path $path)) { break; } else { Start-Sleep -Seconds 1 } }
}
