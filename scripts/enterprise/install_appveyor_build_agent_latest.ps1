$latestVersionUrl = 'https://appveyordownloads.blob.core.windows.net/build-agent/appveyor-build-agent-windows-version.txt'
$regKey = "HKLM:\Software\AppVeyor\Build Agent"

# installation path
$appveyorDir = "$env:ProgramFiles\AppVeyor\BuildAgent"
$backupDir = $appveyorDir + "_backup"

# installed version
$installedVer = ""

# latest version
$latestVersion = $env:APPVEYOR_BUILD_AGENT_LATEST_VERSION_TEST
$latestUrl = $env:APPVEYOR_BUILD_AGENT_LATEST_URL_TEST

function ConfigureNic() {
    $nicSettings = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\External' -ErrorAction SilentlyContinue
    if ($nicSettings.NetworkIpAddress) {
        Write-Host "Network adapter settings found in KVP store:"
        Write-Host "  IPAddress: $($nicSettings.NetworkIpAddress)"
        Write-Host "  SubnetMask: $($nicSettings.NetworkSubnetMask)"
        Write-Host "  DefaultGateway: $($nicSettings.NetworkDefaultGateway)"
        Write-Host "  DnsServerPrimary: $($nicSettings.NetworkDnsServerPrimary)"
        Write-Host "  DnsServerSecondary: $($nicSettings.NetworkDnsServerSecondary)"
        Write-Host "  NetworkDisableNetbios: $($nicSettings.NetworkDisableNetbios)"
        $dnsServers = @()
        if ($nicSettings.NetworkDnsServerPrimary) {
            $dnsServers += $nicSettings.NetworkDnsServerPrimary
        }
        if ($nicSettings.NetworkDnsServerSecondary) {
            $dnsServers += $nicSettings.NetworkDnsServerSecondary
        }

        $nics = Get-WMIObject Win32_NetworkAdapterConfiguration -computername . | where{$_.IPEnabled -eq $true} 
        foreach($nic in $nics) { 
            $ip = ($nic.IPAddress[0])
            if ($ip -eq $nicSettings.NetworkIpAddress) {
                # NIC has been configured already
                break
            }

            $adapter = $nic.GetRelated("Win32_NetworkAdapter")
            if ($adapter.NetConnectionID.startsWith('vEthernet (HNS Internal NIC)')) {
                Write-Host "Skip NIC: $($adapter.NetConnectionID)"
                continue
            }

            # set IP address
            Write-Host "Enable static IP"
            $nic.EnableStatic($nicSettings.NetworkIpAddress, $nicSettings.NetworkSubnetMask) | Out-Null

            # gateway
            Write-Host "Set gateway"
            $nic.SetGateways($nicSettings.NetworkDefaultGateway) | Out-Null

            # set DNS servers
            if ($dnsServers.Length -gt 0) {
                Write-Host "Set DNS servers"
                $nic.SetDNSServerSearchOrder($dnsServers) | Out-Null
            }

            # disable NetBIOS
            if ($nicSettings.NetworkDisableNetbios -eq 'true') {
                Write-Host "Disable NetBIOS"
                $nic.SetTcpipNetbios(2) | Out-Null
            }

            # configure 1st NIC only
            break
        }

        # notify build agent that NIC is already configured
        $env:APPVEYOR_BUILD_AGENT_HYPERV_NIC_CONFIGURED = 'true'
    }
}

function ConfigureHyperV() {
    $agentMode = Get-ItemProperty -Path "HKLM:\Software\AppVeyor\Build Agent" -Name 'Mode' -ErrorAction SilentlyContinue
    if ($agentMode -and $agentMode.Mode -eq 'HyperV') {
        ConfigureNic
    }
}

function Update() {
    # HyperV-specific
    ConfigureHyperV

    # check current installation
    if (Test-Path $appveyorDir) {
	    Write-Host "AppVeyor Build Agent already installed"
	    $versionPath = (Join-Path $appveyorDir "version.txt")

	    # read installed version
	    if (Test-Path $versionPath) {
		    $installedVer = [IO.File]::ReadAllText($versionPath)
            Write-Host "Installed version: $installedVer"
	    }
    }

    # read remote version
    if (-not $latestVersion -or -not $latestUrl) {
        $retry = 0
        for($retry = 0; $retry -lt 5; $retry++) {
            try {
                Write-Host "Fetching latest version attempt #$retry"
                $resp = Invoke-WebRequest $latestVersionUrl -UseBasicParsing -TimeoutSec 5
                $versionData = $resp.content.split(' ')

                if ($versionData.Count -ne 2 -or -not $versionData[0] -or -not $versionData[1]) {
                    Write-Host "Wrong version data - aborting"
                    return
                }

                $latestVersion = $versionData[0]
                $latestUrl = $versionData[1]
                Write-Host "Latest version: $latestVersion"
                break
            } catch {
                # do nothing - just return
                if ($retry -eq 4) {
                    Write-Host "There was an error fetching latest version - aborting"
                    return
                } else {
                    Write-Host "Error fetching the latest version."
                    Start-Sleep -s 2
                }
            }
        }
    } else {
        Write-Host "Latest version override: $latestVersion"
        Write-Host "Latest version URL override: $latestUrl"
    }

    # should we update current installation?
    if($installedVer -eq $latestVersion) {
        Write-Host "The latest AppVeyor Build Agent version is already installed" -ForegroundColor Green
        return
    }

    # backup current version
    if (Test-Path $appveyorDir) {
        Write-Host "Backup current version"
        try {
            [IO.Directory]::Move($appveyorDir, $backupDir)
        } catch {
            Write-Host "Error backup current installation - aborting"
            return
        }
    }

    # download new version
    $tempZip = "$env:TEMP\build-agent-latest.zip"

    try {
        Write-Host "Downloading latest version"
        (New-Object Net.WebClient).DownloadFile($latestUrl, $tempZip)

        # unzip
        Write-Host "Unpacking latest version"
        7z x $tempZip -o"$appveyorDir" | Out-Null

    } catch {
        Write-Host "There was an error downloading latest version"

        # rollback
        if (Test-Path $appveyorDir) {
            Write-Host "Delete partial agent directory"
            Remove-Item $appveyorDir -Recurse -Force
        }
        if (Test-Path $backupDir) {
            Write-Host "Restoring original installation from backup folder"
            [IO.Directory]::Move($backupDir, $appveyorDir)
        }
        return
    }

    # delete backup
    try {
        if (Test-Path $backupDir) {
            Write-Host "Deleting backup folder"
            Remove-Item $backupDir -Recurse -Force
        }
    } catch {
        Write-Host "Error deleting backup folder"
    }

    # delete temp files
    try {
        Remove-Item $tempZip -Force
    } catch {
        Write-Host "Error deleting temp zip file"
    }

    # add AppVeyor to auto-run
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
        -Value "powershell -File `"$appveyorDir\update-appveyor-agent.ps1`""

    Write-Host "AppVeyor Build Agent updated to $latestVersion" -ForegroundColor Green
}

# redirect output to a log file
Start-Transcript -path $env:TEMP\build-agent-update.log -append

# run update
Measure-Command {
    Update
}

# Update Registry
if (-not (Test-Path $regKey)) {
    Write-Host "Adding Registry settings"
    New-Item -Path $regKey -Force | Out-Null
    New-ItemProperty -Path $regKey -Name 'AppVeyorUrl' -Value 'https://ci.appveyor.com' | Out-Null
}

# Update Agent mode if not set
$agentMode = Get-ItemProperty -Path $regKey -Name 'Mode' -ErrorAction SilentlyContinue
if (-not $agentMode) {
    Write-Host "Setting agent mode"
    $mode = 'HyperV'

    $gceAgentSrv = Get-Service GCEAgent -ErrorAction SilentlyContinue
    if ($gceAgentSrv) {
        $mode = 'GCE'
    }

    # set mode
    Set-ItemProperty -Path $regKey -Name 'Mode' -Value $mode
}

# run agent
Write-Host "Starting AppVeyor Build Agent..."

& "$appveyorDir\start-appveyor-agent.ps1"

Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
