Write-Host "Installing Git LFS..." -ForegroundColor Cyan

$exePath = "$env:TEMP\git-lfs-windows-1.4.4.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/github/git-lfs/releases/download/v1.4.4/git-lfs-windows-1.4.4.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

Add-Path "$env:ProgramFiles\Git LFS"
$env:path = "$env:ProgramFiles\Git LFS;$env:path"

git lfs install --force
git lfs

Write-Host "Git LFS installed" -ForegroundColor Green