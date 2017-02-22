function UninstallMiniconda($condaName) {
    $regPath = $null
    $uninstallString = $null

    if(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    } elseif (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    } elseif (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    }

    if($uninstallString) {
        Write-Host "Uninstalling $condaName"
        $uninstallString | out-file "$env:temp\uninstall.cmd" -Encoding ASCII
        & "$env:temp\uninstall.cmd"
        del "$env:temp\uninstall.cmd"
        Remove-Item $regPath
    } else {
        Write-Host "$condaName is not installed"
    }
}

UninstallMiniconda "Python 2.7.13 (Miniconda2 4.3.11 32-bit)"
UninstallMiniconda "Python 2.7.13 (Miniconda2 4.3.11 64-bit)"

Write-Host "Installing Miniconda2 4.3.11 Python 2.7.13 x64..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda2-4.3.11-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda-x64
del $exePath

Write-Host "Installing Miniconda2 4.3.11 Python 2.7.13 x86..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda2-4.3.11-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda
del $exePath

function CheckMiniconda($path) {
    if (-not (Test-Path "$path\python.exe")) { throw "python.exe is missing in $path"; }
    elseif (-not (Test-Path "$path\Scripts\conda.exe")) { throw "conda.exe is missing in $path"; }
    else { Write-Host "$path is OK" -ForegroundColor Green; }
}

CheckMiniconda 'C:\Miniconda'
CheckMiniconda 'C:\Miniconda-x64'
