$token = $env:api_token
$accountName = $env:appveyor_account_name
$projectSlug = $env:deploy_project
$buildVersion = $env:deploy_version
$downloadLocation = $env:appveyor_build_folder
$deployArtifact = $env:deploy_artifact

$apiUrl = 'https://ci.appveyor.com/api'

$headers = @{
  "Authorization" = "Bearer $token"
  "Content-type" = "application/json"
}

# get project with last build details

if($buildVersion) {
    $buildUrl = "$apiUrl/projects/$accountName/$projectSlug/build/$buildVersion"
} else {
    Write-Host "Deploying the most recent build"
    $buildUrl = "$apiUrl/projects/$accountName/$projectSlug"
}
$project = Invoke-RestMethod -Method Get -Uri $buildUrl -Headers $headers

Write-Host "Project: $($project.project.name)"
Write-Host "Build: $($project.build.version)"

# we assume here that build has a single job
# get this job id
$jobId = $project.build.jobs[0].jobId

# get job artifacts (just to see what we've got)
$artifacts = Invoke-RestMethod -Method Get -Uri "$apiUrl/buildjobs/$jobId/artifacts" -Headers $headers

if($artifacts.Length -eq 0) {
    Write-Host "Build does not contain artifacts" -ForegroundColor Yellow
    return
}

$artifactsDownloaded = 0

# download all artifacts
for($i = 0; $i -lt $artifacts.length; $i++) {

    # filter artifacts if specified
    if($deployArtifact -and -not ($artifacts[$i].fileName -eq $deployArtifact -or $artifacts[$i].name -eq $deployArtifact  -or [IO.Path]::GetFileName($artifacts[$i].fileName) -eq $deployArtifact)) {
        continue
    }

    if($artifactsDownloaded -eq 0) {
        Write-Host "Downloading build artifacts"
    }

    $artifactRelativePath = $artifacts[$i].fileName
    $artifactFileName = [IO.Path]::GetFileName($artifactRelativePath)

    Write-Host "[$($i + 1) of $($artifacts.length)] $artifactFileName -> `$env:appveyor_build_folder\$artifactFileName" -ForegroundColor Gray

    # artifact will be downloaded as 
    $localArtifactPath = "$downloadLocation\$artifactFileName"

    # download artifact
    # -OutFile - is local file name where artifact will be downloaded into
    Invoke-WebRequest -Method Get -Uri "$apiUrl/buildjobs/$jobId/artifacts/$artifactRelativePath" `
         -OutFile $localArtifactPath -Headers @{ "Authorization" = "Bearer $token" }

    $artifactsDownloaded++
}

if($artifactsDownloaded -eq 0) {
    Write-Host "No artifacts were downloaded" -ForegroundColor Yellow
    return
}
