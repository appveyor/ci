$installerUrl = 'http://www.appveyor.com/downloads/build-agent/latest/AppveyorBuildAgent.msi'
$installerFileName = "$($env:TEMP)\AppveyorBuildAgent.msi"
 
$process = Get-Process -Name 'Appveyor.BuildAgent.Service' -ErrorAction SilentlyContinue
if($process) {
    $process | Stop-Process -Force
}
$process = Get-Process -Name 'Appveyor.BuildAgent.Interactive' -ErrorAction SilentlyContinue
if($process) {
    $process | Stop-Process -Force
}
 
(New-Object Net.WebClient).DownloadFile($installerUrl, $installerFileName)
cmd /c start /wait msiexec /i $installerFileName /quiet APPVEYOR_MODE=Azure
Remove-Item $installerFileName

# display appveyor version
& "C:\Program Files\AppVeyor\BuildAgent\appveyor.exe" version

Clear-EventLog -LogName AppVeyor -ErrorAction SilentlyContinue