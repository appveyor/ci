Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
	-Value 'powershell -File "C:\Program Files\AppVeyor\BuildAgent\start-appveyor-agent.ps1"'
