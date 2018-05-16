#$env:REPO_CLONE_ATTEMPTS=2
#$env:REPO_CLONE_TIMEOUT=180
#$env:REPO_CLONE_PROTOCOL='https'

$cloneFolder = $env:APPVEYOR_BUILD_FOLDER

if($env:REPO_CLONE_PROTOCOL -eq 'https') {
    $cloneRepo = "https://github.com/$env:APPVEYOR_REPO_NAME.git"
} else {
    $cloneRepo = "git@github.com:$env:APPVEYOR_REPO_NAME.git"
}

$timeoutSeconds = 180
if($env:REPO_CLONE_TIMEOUT) {
    $timeoutSeconds = [convert]::ToInt32($env:REPO_CLONE_TIMEOUT)
}

$attempts = 2
if($env:REPO_CLONE_ATTEMPTS) {
    $attempts = [convert]::ToInt32($env:REPO_CLONE_ATTEMPTS)
}

while($attempts-- -gt 0) {
    if(Test-Path $cloneFolder) {
        Write-Host "Cleaning up ..."
        Get-ChildItem -Path $cloneFolder -Include * -Hidden -Recurse | foreach { Remove-Item $_.FullName -Force -Recurse }
    } else {
        Write-Host "Creating folder..."
        New-Item $cloneFolder -ItemType directory | Out-Null        
    }

    Write-Host "Cloning..."

    $si = new-object System.Diagnostics.ProcessStartInfo
    $si.UseShellExecute = $false
    $si.FileName = "git"
    $si.Arguments = "clone $cloneRepo `"$cloneFolder`""
    $p = [diagnostics.process]::Start($si)

    if($p.WaitForExit($timeoutSeconds * 1000)) {
        # success
        break 
    } else {
        # stuck
        Write-Host "git clone has stuck." -ForegroundColor Yellow
        Write-Host "Terminating git process..."
        cmd /c taskkill /PID $p.Id /F /T
        Start-Sleep -s 5
    }
}
