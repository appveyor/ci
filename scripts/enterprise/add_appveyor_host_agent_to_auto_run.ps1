if (Get-Service Appveyor.HostAgent -ErrorAction Ignore) {
  Stop-Service Appveyor.HostAgent -Force
  Set-Service Appveyor.HostAgent -StartupType Disabled
}
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Appveyor.HostAgent" `
	-Value "C:\Program Files\AppVeyor\HostAgent\Appveyor.HostAgent.exe"
