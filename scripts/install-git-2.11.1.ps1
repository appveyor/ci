Write-Host "Uninstalling existing Git..."
"`"C:\Program Files\Git\unins000.exe`" /silent" | out-file "$env:TEMP\uninstall-git.cmd" -Encoding ASCII
& $env:TEMP\uninstall-git.cmd | Out-Null
Write-Host "Downloading Git 2.11.1..."
$exePath = "$env:TEMP\Git-2.11.1-64-bit.exe"
(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.11.1.windows.1/Git-2.11.1-64-bit.exe', $exePath)
Write-Host "Installing Git 2.11.1..."
cmd /c start /wait $exePath /VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS="icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh"
