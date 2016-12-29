Write-Host "Installing Microsoft Build Tools 2013..." -ForegroundColor Cyan

$msbuild12Path = "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"

if(-not (Test-Path $msbuild12Path)) {
    $exePath = "$($env:USERPROFILE)\BuildTools_Full12.exe"
    (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/9/B/B/9BB1309E-1A8F-4A47-A6C5-ECF76672A3B3/BuildTools_Full.exe', $exePath)
    cmd /c start /wait $exePath /quiet
}

Add-SessionPath $msbuild12Path
Add-Path $msbuild12Path

Write-Host "Microsoft Build Tools 2013 installed" -ForegroundColor Green
