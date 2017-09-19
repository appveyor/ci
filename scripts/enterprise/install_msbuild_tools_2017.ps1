Write-Host "Installing Microsoft Build Tools 2017..." -ForegroundColor Cyan

$msbuild15Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin"

if(-not (Test-Path $msbuild15Path)) {
    $exePath = "$env:TEMP\vs_BuildTools.exe"
    (New-Object Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/11346809/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe', $exePath)
    cmd /c start /wait $exePath --passive --norestart
    del $exePath
}

Add-SessionPath $msbuild15Path
Add-Path $msbuild15Path

Write-Host "Microsoft Build Tools 2017 installed" -ForegroundColor Green
