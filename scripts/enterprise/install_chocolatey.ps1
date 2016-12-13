
if(Test-Path 'C:\ProgramData\chocolatey\bin') {
    # update
    Write-Host "Updating Chocolatey..." -ForegroundColor Cyan
    choco upgrade chocolatey
} else {
    # install
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco --version

# enable -y
$configPath = "C:\ProgramData\chocolatey\config\chocolatey.config"
$config = [xml](Get-Content $configPath)
$allowGlobalConfirmation = $config.chocolatey.features.feature | where {$_.name -eq 'allowGlobalConfirmation'}
$allowGlobalConfirmation.enabled = 'true'
$allowGlobalConfirmation.setExplicitly = 'true'
$config.Save($configPath)

Write-Host "Chocolatey installed" -ForegroundColor Green