$user = "$env:COMPUTERNAME\$env:USERNAME"
$credential = Get-Credential -UserName $user -Message "Please enter username and password of the account to run AppVeyor Build Agent:"
$password = $credential.GetNetworkCredential().password
$action = New-ScheduledTaskAction -Execute 'C:\Program Files\AppVeyor\BuildAgent\Appveyor.BuildAgent.Service.exe'
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName 'Start AppVeyor Build Agent' -Action $action -Trigger $trigger -User $user -Password $password -RunLevel Highest