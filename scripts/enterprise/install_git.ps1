Write-Host "Installing Git 2.14.1..." -ForegroundColor Cyan

$exePath = "$env:TEMP\Git-2.14.1-64-bit.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.14.1.windows.1/Git-2.14.1-64-bit.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS="icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh" /LOG
del $exePath

Add-Path "$env:ProgramFiles\Git\cmd"
$env:path = "$env:ProgramFiles\Git\cmd;$env:path"

Add-Path "$env:ProgramFiles\Git\usr\bin"
$env:path = "$env:ProgramFiles\Git\usr\bin;$env:path"

#Remove-Item 'C:\Program Files\Git\mingw64\etc\gitconfig'
git config --global core.autocrlf input
git config --system --unset credential.helper
#git config --global credential.helper store

git --version
Write-Host "Git installed" -ForegroundColor Green
