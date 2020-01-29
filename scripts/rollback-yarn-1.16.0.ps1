function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName.Contains($productName) } `
        | Select UninstallString).UninstallString
}

$uninstallCommand = GetUninstallString "Yarn"

if ($uninstallCommand) {
    Write-Host "Uninstalling existing installation of Yarn ..." -ForegroundColor Cyan

    $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet

    Write-Host "Uninstalled" -ForegroundColor Green
}

Write-Host "Installing Yarn ..." -ForegroundColor Cyan
$msiPath = "$($env:TEMP)\yarn.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/yarnpkg/yarn/releases/download/v1.16.0/yarn-1.16.0.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet /qn
del $msiPath

Write-Host "Yarn installed" -ForegroundColor Green

yarn --version
