[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# What Windows is that?
$osVer = [System.Environment]::OSVersion.Version

# Major  Minor  Build  Revision
# -----  -----  -----  --------
# 10     0      17763  0

# Windows Server 2016	10.0.14393
# Windows 10 (1709)		10.0.16299
# Windows 10 (1803)		10.0.17134
# Windows Server 2019	10.0.17763

function PullRunDockerImages($minOsBuild, $serverCoreTag, $nanoServerTag) {
	$hypervFeature = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online)
	$hypervInstalled = ($hypervFeature -and $hypervFeature.State -eq 'Enabled')

	if ($osVer.Build -ge $minOsBuild) {
		# Windows Server 2016 or above
		
		$isolation = $null
		if ($osVer.Build -gt $minOsBuild -and $hypervInstalled) {
			$isolation = 'hyperv'
		} elseif ($osVer.Build -eq $minOsBuild) {
			$isolation = 'default'
		}
		
		if ($isolation) {
			Write-Host "Pulling and running '$serverCoreTag' images in '$isolation' mode"
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}

Switch-DockerLinux
docker run --rm busybox echo hello_world
docker run --rm alpine echo hello_world

Switch-DockerWindows
PullRunDockerImages 14393 'ltsc2016' 'sac2016'
PullRunDockerImages 17134 '1803' '1803'
PullRunDockerImages 17763 'ltsc2019' '1809'

Switch-DockerLinux

Set-Content -Path $env:SystemDrive\prepare-docker-finished.txt -Value finished
