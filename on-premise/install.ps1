# Script for installing/updating AppVeyor on-premise

# download installer to PSModulesPath

Write-Host "Updating AppVeyor Installer module..." -ForegroundColor Cyan
$userModulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
$appveyorModulePath = "$userModulesPath\appveyor-installer"

# create module directory
if(-not (Test-Path $appveyorModulePath)) {
    New-Item -Path $appveyorModulePath -ItemType Directory -Force | Out-Null
}

# download installer module
Write-Host "Downloading appveyor-installer.psm1 to $appveyorModulePath"
(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/appveyor/ci/master/on-premise/appveyor-installer.psm1', "$appveyorModulePath\appveyor-installer.psm1")

$psPath = $env:PSModulePath
if($psPath.indexOf($userModulesPath) -eq -1) {
    Write-Host "Updating PSModulePath variable"
    $psPath += ";$userModulesPath"
    $env:PSModulePath = $psPath
    [Environment]::SetEnvironmentVariable("PSModulePath",$psPath, "machine")
}

Write-Host "Loading appveyor-installer module..."
Remove-Module appveyor-installer -ErrorAction SilentlyContinue
Import-Module appveyor-installer
Write-Host "appveyor-installer module has been loaded." -ForegroundColor Green
