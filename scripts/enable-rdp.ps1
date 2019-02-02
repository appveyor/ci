function ChangePassword($password) {
  $objUser = [ADSI]("WinNT://$($env:computername)/appveyor")
  $objUser.SetPassword($password)
  $objUser.CommitChanges()
}

function WaitInitialPasswordChange() {
  $end = (Get-Date).AddMinutes(1)
  $changed = $false
  while (!$changed  -and  ($end -gt (Get-Date))) {
    Write-host "waiting for password change"
    Get-ItemProperty 'HKLM:\SOFTWARE\Appveyor\Build Agent\State'
    $changed =  (Get-ItemProperty 'HKLM:\SOFTWARE\Appveyor\Build Agent\State' -Name AgentPasswordChanged -ErrorAction Ignore).AgentPasswordChanged -eq "true"
    if (!$changed) {Write-host "."; Sleep 5}
  }
}

if((Test-Path variable:islinux) -and $isLinux) {
  Write-Warning "RDP access is not supported on Linux. Please use SSH (https://www.appveyor.com/docs/how-to/ssh-to-build-worker/)."
  return
}

# get current IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like 'ethernet*'}).IPAddress
$port = 3389

# get password or generate
$password = ''
if($env:appveyor_rdp_password) {
    # take from environment variable
    $password = $env:appveyor_rdp_password       
    WaitInitialPasswordChange
    ChangePassword -password $password
    [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", $password)
} else {
    # get existing password
    $password = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", '')
}

if($ip.StartsWith('172.24.')) {
    $port = 33800 + ($ip.split('.')[2] - 16) * 256 + $ip.split('.')[3]
} elseif ($ip.StartsWith('192.168.') -or $ip.StartsWith('10.240.')) {
    # new environment - behind NAT
    $port = 33800 + ($ip.split('.')[2] - 0) * 256 + $ip.split('.')[3]
} elseif ($ip.StartsWith('10.0.')) {
    $port = 33800 + ($ip.split('.')[2] - 0) * 256 + $ip.split('.')[3]
}

# get external IP
$ip = (New-Object Net.WebClient).DownloadString('https://www.appveyor.com/tools/my-ip.aspx').Trim()

# allow RDP on firewall
Enable-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-in)'

Write-Host "Remote Desktop connection details:" -ForegroundColor Yellow
Write-Host "  Server: $ip`:$port" -ForegroundColor Gray
Write-Host "  Username: appveyor" -ForegroundColor Gray
if(-not $env:appveyor_rdp_password) {
    Write-Host "  Password: $password" -ForegroundColor Gray
}

if($blockRdp) {
    $path = "$($env:USERPROFILE)\Desktop\Delete me to continue build.txt"
    # create "lock" file.
    Set-Content -Path $path -Value ''    
    Write-Warning "Build paused. To resume it, open a RDP session to delete 'Delete me to continue build.txt' file on Desktop."
    # wait until "lock" file is deleted by user.
    while(Test-Path $path) {
      Start-Sleep -Seconds 1
    }
    Write-Host "Build lock file has been deleted. Resuming build."
}
