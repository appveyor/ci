Write-Host "Installing Git 2.11.1..." -NoNewLine
$zipPath = "$env:TEMP\PortableGit-2.11.1-64-bit.7z.exe"
(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.11.1.windows.1/PortableGit-2.11.1-64-bit.7z.exe', $zipPath)
7z x $zipPath -aoa -o'C:\Program Files\Git' mingw64\bin | Out-Null
Write-Host "OK" -ForegroundColor Green
