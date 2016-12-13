Write-Host "Installing xUnit 2.0..." -ForegroundColor Cyan
$xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit20"
$tempPath = "$env:USERPROFILE\xunit20"
nuget install xunit.runner.console -excludeversion -outputdirectory $tempPath

[IO.Directory]::Move("$tempPath\xunit.runner.console\tools", $xunitPath)
del $tempPath -Recurse -Force

[Environment]::SetEnvironmentVariable("xunit20", $xunitPath, "Machine")
Write-Host "xUnit 2.0 installed" -ForegroundColor Green