param (
    [Parameter(Mandatory=$true)]
    [string]$AccountName,
        
    [Parameter(Mandatory=$true)]
    [string]$ProjectSlug,
        
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
        
    [Parameter(Mandatory=$true)]
    [string]$RepoCommit,
        
    [Parameter(Mandatory=$true)]
    [int]$TimeOutMins
        
)
    
$token = $ApiKey
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-type" = "application/json"
}
    
[datetime]$stop = ([datetime]::Now).AddMinutes($TimeOutMins)
[bool]$success = $false
    
while(!$success -and ([datetime]::Now) -lt $stop) {
    $project = Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$AccountName/$ProjectSlug" -Headers $headers -Method GET
    Write-host "Last build commit:"
    $project.build.commitId
    Write-host "Last build status:"
    $project.build.status
    $success = ($project.build.commitId -eq $RepoCommit) -and ($project.build.status -eq "success")
    if (!$success) {
        Start-sleep 5
    }
}
    
if (!$success) {
    throw "Build did not finished OK in $TimeOutMins minutes"
}
