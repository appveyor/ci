function Get-Version([string]$str) {
    $versionDigits = $str.Split('.')
    $version = @{
        major = -1
        minor = -1
        build = -1
        revision = -1
        number = 0
    }

    if ($versionDigits.Length -gt 0) {
        $version.major = [int]$versionDigits[0]
    }
    if ($versionDigits.Length -gt 1) {
        $version.minor = [int]$versionDigits[1]
    }
    if ($versionDigits.Length -gt 2) {
        $version.build = [int]$versionDigits[2]
    }
    if ($versionDigits.Length -gt 3) {
        $version.revision = [int]$versionDigits[3]
    }

    for ($i = 0; $i -lt $versionDigits.Length; $i++) {
        $version.number += [long]$versionDigits[$i] -shl 16 * (3 - $i)
    }

    return $version
}

function Get-NodeJsInstallPackage {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$version,

        [Parameter(Mandatory=$false)]
        [string]$bitness = 'x86'
    )

    $v = Get-Version $version

    if ($v.Major -ge 4 -and $bitness -eq 'x86') {
        $packageUrl = "https://nodejs.org/dist/v$version/node-v$version-x86.msi"
    } elseif ($v.Major -ge 4 -and $bitness -eq 'x64') {
        $packageUrl = "https://nodejs.org/dist/v$version/node-v$version-x64.msi"
    } elseif ($v.Major -eq 0 -and $bitness -eq 'x86') {
        $packageUrl = "https://nodejs.org/dist/v$version/node-v$version-x86.msi"
    } elseif ($v.Major -ge 1 -and $bitness -eq 'x86') {
        $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x86.msi"
    } elseif ($v.Major -eq 0) {
        $packageUrl = "https://nodejs.org/dist/v$version/x64/node-v$version-x64.msi"
    } elseif ($v.Major -ge 1) {
        $packageUrl = "httpss://iojs.org/dist/v$version/iojs-v$version-x64.msi"
    }

    $packageFileName = Join-Path ([IO.Path]::GetTempPath()) $packageUrl.Substring($packageUrl.LastIndexOf('/') + 1)
    (New-Object Net.WebClient).DownloadFile($packageUrl, $packageFileName)
    return $packageFileName
}

function Get-InstalledNodeJsVersion() {
    $nodePath = (cmd /c where node.exe)
    if (-not $nodePath) {
       $nodePath = (cmd /c where iojs.exe)
    }

    if ($nodePath) {
        $bitness = 'x64'
        if ($nodePath.indexOf('(x86)') -ne -1) {
            $bitness = 'x86'
        }
        return @{
            bitness = $bitness
            version = (. $nodePath -v).substring(1)
        }
    } else {
        return $null
    }
}

function Remove-NodeJsInstallation {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$version,

        [Parameter(Mandatory=$true)]
        [string]$bitness
    )

    Write-Host "Uninstalling $(ProductName($version)) v$version ($bitness)..."
    $packageFileName = Get-NodeJsInstallPackage $version $bitness
    cmd /c start /wait msiexec /x $packageFileName /quiet
}

function Start-NodeJsInstallation {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$version,

        [Parameter(Mandatory=$false)]
        [string]$bitness = 'x86'
    )

    $v = Get-Version $version
    if ($v.Major -eq 0 -or $v.Major -ge 4) {
        $features = 'NodeRuntime,npm'
    } else {
        $features = 'NodeRuntime,NodeAlias,npm'
    }

    Write-Host "Installing $(ProductName($version)) v$version ($bitness)..."
    $packageFileName = Get-NodeJsInstallPackage $version $bitness
    cmd /c start /wait msiexec /i "$packageFileName" /q "ADDLOCAL=$features"
}

function Update-NodeJsInstallation {
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$version,

        [Parameter(Mandatory=$false)]
        [string]$bitness = 'x86'
    )

    $installedVersion = Get-InstalledNodeJsVersion

    if ($installedVersion -eq $null -or $installedVersion.version -ne $version -or $installedVersion.bitness -ne $bitness) {
        Write-Host "Updating $(ProductName($version)) v$version ($bitness)"
        if ($installedVersion) {
            Remove-NodeJsInstallation $installedVersion.version $installedVersion.bitness
        }
        Start-NodeJsInstallation $version $bitness
    }
}

function Get-NodeJsLatestBuild([string]$majorVersion) {
    # fetch available distros
    $v = Get-Version $majorVersion
    if ($v.Major -eq 0 -or $v.Major -ge 4) {
        $content = (New-Object Net.WebClient).DownloadString('https://nodejs.org/dist/')
    } else {
        $content = (New-Object Net.WebClient).DownloadString('https://iojs.org/dist/')
    }

    # parse versions and find the latest
    $versions = (Select-String '>v(\d*\.\d*\.\d*)/<' -input $content -allmatches `
        | % {$_.matches} | % { $_.groups[1].value } `
        | Where-Object {"$_.".StartsWith("$majorVersion.") })

    if ($versions.Count -eq 0) {
        return $null
    } elseif ($versions.indexOf('.') -ne -1) {
        return $versions
    } else {
        $maxVersion = $versions[0]
        for ($i = 0; $i -lt $versions.Count; $i++) {
            if ((Get-Version $versions[$i]).number -gt (Get-Version $maxVersion).number) {
                $maxVersion = $versions[$i]
            }
        }
        return $maxVersion
    }
}

function ProductName($version) {
    $v = Get-Version $version
    if ($v.Major -eq 0 -or $v.Major -ge 4) {
        return 'Node.js'
    } else {
        return 'io.js'
    }
}

# export module members
Export-ModuleMember -Function Get-NodeJsInstallPackage,Get-InstalledNodeJsVersion,Remove-NodeJsInstallation,Start-NodeJsInstallation,Update-NodeJsInstallation,Get-NodeJsLatestBuild
