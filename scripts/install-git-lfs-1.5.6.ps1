Write-Host "Installing Git LFS 1.5.6..." -NoNewLine
$zipPath = "$env:TEMP\git-lfs-windows-amd64-1.5.6.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/git-lfs/git-lfs/releases/download/v1.5.6/git-lfs-windows-amd64-1.5.6.zip', $zipPath)
7z x $zipPath -y -o"$env:ProgramFiles\Git LFS" | Out-Null
Write-Host "OK" -ForegroundColor Green
