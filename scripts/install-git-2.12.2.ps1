Write-Host "Installing Git 2.12.2..." -NoNewLine
$exePath = "$env:TEMP\Git-2.12.2-64-bit.exe"
(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.12.2.windows.1/Git-2.12.2-64-bit.exe', $exePath)
cmd /c start /wait $exePath /VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS="icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh"
Write-Host "OK" -ForegroundColor Green
