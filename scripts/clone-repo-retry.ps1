#$env:REPO_CLONE_ATTEMPTS=2
#$env:REPO_CLONE_TIMEOUT=60
#$env:REPO_CLONE_PROTOCOL='https'

$cloneFolder = $env:APPVEYOR_BUILD_FOLDER

if($env:REPO_CLONE_PROTOCOL -eq 'https') {
    $cloneRepo = "https://github.com/$env:APPVEYOR_REPO_NAME.git"
} else {
    $cloneRepo = "git@github.com:$env:APPVEYOR_REPO_NAME.git"
}

$timeoutSeconds = 60
if($env:REPO_CLONE_TIMEOUT) {
    $timeoutSeconds = [convert]::ToInt32($env:REPO_CLONE_TIMEOUT)
}

$attempts = 2
if($env:REPO_CLONE_ATTEMPTS) {
    $attempts = [convert]::ToInt32($env:REPO_CLONE_ATTEMPTS)
}

# delete folder if exists
while($attempts-- -gt 0) {
    if(Test-Path $cloneFolder) {
        Write-Host "Cleaning up ..."
        Remove-Item $cloneFolder -Recurse -Force
    }

    Write-Host "Creating folder..."
    New-Item $cloneFolder -ItemType directory | Out-Null

    Write-Host "Clonning..."

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
    }
}
