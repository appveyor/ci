Write-Host -NoNewline "Installing NuGet 3.4.4..."
if (Test-Path 'C:\Tools\NuGet3') { $nugetDir = 'C:\Tools\NuGet3' } else { $nugetDir = 'C:\Tools\NuGet' }
(New-Object Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/v3.4.4/NuGet.exe', "$nugetDir\NuGet.exe")
Write-Host "OK" -ForegroundColor Green
