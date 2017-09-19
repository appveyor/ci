Write-Host "Installing Git LFS..." -ForegroundColor Cyan

# delete existing Git LFS
del 'C:\Program Files\Git\mingw64\bin\git-lfs.exe'

$exePath = "$env:TEMP\git-lfs-windows-2.2.1.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/git-lfs/git-lfs/releases/download/v2.2.1/git-lfs-windows-2.2.1.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

Add-Path "$env:ProgramFiles\Git LFS"
$env:path = "$env:ProgramFiles\Git LFS;$env:path"

git lfs install --force
git lfs version

Write-Host "Git LFS installed" -ForegroundColor Green
