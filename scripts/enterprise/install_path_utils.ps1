$pathUtilsPath = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules\path-utils"
New-Item $pathUtilsPath -ItemType Directory -Force
(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/appveyor/ci/master/scripts/path-utils.psm1', "$pathUtilsPath\path-utils.psm1")
Remove-Module path-utils -ErrorAction SilentlyContinue
Import-Module path-utils

$UserModulesPath = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
$PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
if(-not $PSModulePath.contains($UserModulesPath)) {
    [Environment]::SetEnvironmentVariable('PSModulePath', "$PSModulePath;$UserModulesPath", 'Machine')
}