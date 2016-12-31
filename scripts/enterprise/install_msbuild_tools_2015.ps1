Write-Host "Installing Microsoft Build Tools 2015..." -ForegroundColor Cyan

$msbuild14Path = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin"

if(-not (Test-Path $msbuild14Path)) {
    $exePath = "$($env:USERPROFILE)\BuildTools_Full15.exe"
    (New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe', $exePath)
    cmd /c start /wait $exePath /quiet
}

Add-SessionPath $msbuild14Path
Add-Path $msbuild14Path

Write-Host "Microsoft Build Tools 2015 installed" -ForegroundColor Green
