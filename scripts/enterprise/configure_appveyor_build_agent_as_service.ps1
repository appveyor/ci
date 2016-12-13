$user = "$env:COMPUTERNAME\$env:USERNAME"
$credential = Get-Credential -UserName $user -Message "Please enter username and password of the account to run AppVeyor Build Agent:"

New-Service -Name 'Appveyor.BuildAgent' -DisplayName 'AppVeyor Build Agent' -Description 'Runs AppVeyor builds on remote server' `
    -BinaryPathName "$env:ProgramFiles\AppVeyor\BuildAgent\Appveyor.BuildAgent.Service.exe" -StartupType Automatic `
    -Credential $credential

Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 120000 # 2 minutes