Write-Host "Installing MSpec..." -ForegroundColor Cyan
$mspecPath = "$env:SYSTEMDRIVE\Tools\MSpec"
$tempPath = "$env:USERPROFILE\MSpec"
nuget install Machine.Specifications.Runner.Console -excludeversion -outputdirectory $tempPath

[IO.Directory]::Move("$tempPath\Machine.Specifications.Runner.Console\tools", $mspecPath)
del $tempPath -Recurse -Force

Add-Path $mspecPath
Add-SessionPath $mspecPath
Write-Host "MSpec installed" -ForegroundColor Green