# Installer utilities

# check operating system
$os = (Get-CimInstance Win32_OperatingSystem)
$osVersion = [version]$os.Version
$validOs = $osVersion.Major -ge 6 -and $osVersion.Minor -ge 2
$isServerOs = ($os.Name.indexOf("Server") -ne -1)
if(-not $validOs) {
    Write-Host "AppVeyor cannot be installed on $($os.Name.Split('|')[0])" -ForegroundColor White -BackgroundColor Red
    Write-Host ""
    Write-Host "The following operating systems are supported:"
    Write-Host "  Windows Server 2012 R2" # IIS 8.5
    Write-Host "  Windows Server 2012"    # IIS 8.0
    Write-Host "  Windows 8.1"            # IIS 8.5
    Write-Host "  Windows 8"              # IIS 8.0
}

cd $env:USERPROFILE

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
[Reflection.Assembly]::LoadFile("$env:SystemRoot\system32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null

Remove-Module path-utils -ErrorAction SilentlyContinue
Import-Module path-utils -ErrorAction SilentlyContinue

$appveyorInstallRegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\AppVeyor\Install"

function Get-RandomPassword {
    $alphabets = "abcdefghijklmnopqstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()".ToCharArray()
    $length = 12
    $password = ""

    for ($i = 0; $i -le $length; $i++)
    {
        $password += $alphabets[(Get-Random -Minimum 0 -Maximum ($alphabets.Length - 1))]
    }
    return $password
}

function Get-InstallData($key) {
    return [Microsoft.Win32.Registry]::GetValue($appveyorInstallRegistryKey, $key, $null)
}

function Set-InstallData($key, $value) {
    [Microsoft.Win32.Registry]::SetValue($appveyorInstallRegistryKey, $key, $value)
}

function Use-InstallData($key, $value) {
    $storedValue = Get-InstallData $key
    if($storedValue -eq $null) {
        $storedValue = $value
        Set-InstallData $key $storedValue
    }
    return $storedValue
}

# AppVeyor URLs and Paths
$appveyorWorkerUrl = 'http://www.appveyor.com/downloads/onprem/Appveyor.Worker.zip'
$appveyorWorkerPath = "$env:ProgramFiles\AppVeyor\Worker"
$appveyorWebUrl = 'http://www.appveyor.com/downloads/onprem/Appveyor.Web.zip'
$appveyorWebPath = "$env:ProgramFiles\AppVeyor\Web"
$appveyorBuildAgentUrl = 'http://www.appveyor.com/downloads/onprem/Appveyor.BuildAgent.zip'
$appveyorBuildAgentPath = "$env:ProgramFiles\AppVeyor\BuildAgent"

# misc
$appveyorServerRegistryKey = "HKLM:\SOFTWARE\AppVeyor\Server"
$appveyorBuildAgentRegistryKey = "HKLM:\SOFTWARE\AppVeyor\Build Agent"
$appveyorAuthorizationToken = Use-InstallData "AppVeyor authorization token" ([Guid]::NewGuid().ToString())
$googleAnalyticsId = ""
$appveyorArtifactsStoragePath = "$env:SystemDrive\AppVeyor\Artifacts"

# security
$appveyorSecurityMasterKey = Use-InstallData "AppVeyor security master key" ([Guid]::NewGuid().ToString())

# SQL Server
$sqlServerInstance = 'SQL2014'
$sqlServerSaPassword = 'Password12!'

# Service Bus
$serviceBusUsername = "sbadmin"
$serviceBusUserPassword = Use-InstallData "Service Bus user password" (Get-RandomPassword)

# Redis
$redisServer = "localhost"
$redisPort = "6379"

# SQL database
$appveyorDatabaseName = 'AppveyorCI'
$appveyorDatabaseUserName = 'AppveyorCI'
$appveyorDatabaseUserPassword = Use-InstallData "AppVeyor database user password" (Get-RandomPassword)

$scripts = @{}

function New-LocalUser ($username, $password, $description) {
    Write-Host "Creating new local user account '$username'..." -ForegroundColor Cyan

    $user = [ADSI]"WinNT://$env:ComputerName/$username,user" 
    if(-not $user.Name) {
        $computer = [ADSI]"WinNT://$env:ComputerName"
        $user = $computer.Create("User", $username)
        $user.setpassword($password)
        $user.SetInfo()
        $user.description = $description
        $user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
        $user.SetInfo()
        #$OBjOU = [ADSI]"WinNT://$computer/$group,group"
        #$OBjOU.Add("WinNT://$computer/$user")
        Write-Host "User account created" -ForegroundColor Green
    } else {
        Write-Host "User account already exists" -ForegroundColor Yellow
    }
}

function Grant-LogonAsService {
    param($accountToAdd)
    #written by Ingo Karstein, http://blog.karstein-consulting.com
    #  v1.0, 01/03/2014

    ## <--- Configure here

    if( [string]::IsNullOrEmpty($accountToAdd) ) {
	    Write-Host "no account specified"
	    exit
    }

    ## ---> End of Config

    $sidstr = $null
    try {
	    $ntprincipal = new-object System.Security.Principal.NTAccount "$accountToAdd"
	    $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	    $sidstr = $sid.Value.ToString()
    } catch {
	    $sidstr = $null
    }

    Write-Host "Account: $($accountToAdd)" -ForegroundColor DarkCyan

    if( [string]::IsNullOrEmpty($sidstr) ) {
	    Write-Host "Account not found!" -ForegroundColor Red
	    exit -1
    }

    Write-Host "Account SID: $($sidstr)" -ForegroundColor DarkCyan

    $tmp = [System.IO.Path]::GetTempFileName()

    Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
    secedit.exe /export /cfg "$($tmp)" 

    $c = Get-Content -Path $tmp 

    $currentSetting = ""

    foreach($s in $c) {
	    if( $s -like "SeServiceLogonRight*") {
		    $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		    $currentSetting = $x[1].Trim()
	    }
    }

    if( $currentSetting -notlike "*$($sidstr)*" ) {
	    Write-Host "Modify Setting ""Logon as a Service""" -ForegroundColor DarkCyan
	
	    if( [string]::IsNullOrEmpty($currentSetting) ) {
		    $currentSetting = "*$($sidstr)"
	    } else {
		    $currentSetting = "*$($sidstr),$($currentSetting)"
	    }
	
	    Write-Host "$currentSetting"
	
	    $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@

	    $tmp2 = [System.IO.Path]::GetTempFileName()
	
	
	    Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
	    $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force

	    #notepad.exe $tmp2
	    Push-Location (Split-Path $tmp2)
	
	    try {
		    secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
		    #write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
	    } finally {	
		    Pop-Location
	    }
    } else {
	    Write-Host "NO ACTIONS REQUIRED! Account already in ""Logon as a Service""" -ForegroundColor DarkCyan
    }

    Write-Host "Done." -ForegroundColor DarkCyan
}

$scripts["Set_PS_Unrestricted"] = {
    Write-Host "Changing PS execution policy to Unrestricted" -ForegroundColor Cyan
    Set-ExecutionPolicy Unrestricted -Force
}

$scripts["Disable_ServerManager"] = {
    Write-Host "Disabling Server Manager auto-start" -ForegroundColor Cyan
    $serverManagerMachineKey = "HKLM:\SOFTWARE\Microsoft\ServerManager"
    $serverManagerUserKey = "HKCU:\SOFTWARE\Microsoft\ServerManager"
    if(Test-Path $serverManagerMachineKey) {
        Set-ItemProperty -Path $serverManagerMachineKey -Name "DoNotOpenServerManagerAtLogon" -Value 1
        Write-Host "Disabled Server Manager at logon for all users" -ForegroundColor Green
    }
    if(Test-Path $serverManagerUserKey) {
        Set-ItemProperty -Path $serverManagerUserKey -Name "CheckedUnattendLaunchSetting" -Value 0
        Write-Host "Disabled Server Manager for current user" -ForegroundColor Green
    }
}

$scripts["Disable_IE_ESC"] = {
    Write-Host "Disabling Internet Explorer ESC" -ForegroundColor Cyan
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    if((Test-Path $AdminKey) -or (Test-Path $UserKey)) {
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer
        Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
    }
}

$scripts["Disable_UAC"] = {
    Write-Host "Disabling UAC" -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}

$scripts["Disable_WER"] = {
    Write-Host "Disabling Windows Error Reporting (WER)" -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "ForceQueue" -Value 1
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\Consent" -Name "DefaultConsent" -Value 1
    Write-Host "Windows Error Reporting (WER) dialog has been disabled." -ForegroundColor Green    
}

$scripts["Initial_Setup"] = @(
    "Set_PS_Unrestricted",
    "Disable_ServerManager",
    "Disable_IE_ESC",
    "Disable_UAC",
    "Disable_WER"
)

$scripts["PathUtils"] = {
    Write-Host "Installing path-utils PowerShell module..." -ForegroundColor Cyan
    $userModulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
    $pathUtilsModulePath = "$userModulesPath\path-utils"
    if(-not (Test-Path $userModulesPath)) {
        New-Item -Path $userModulesPath -ItemType Directory -Force | Out-Null
    }
    
    if(-not (Test-Path $pathUtilsModulePath)) {
        New-Item -Path $pathUtilsModulePath -ItemType Directory -Force | Out-Null
    }

    (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/appveyor/ci/master/scripts/path-utils.psm1', "$pathUtilsModulePath\path-utils.psm1")
    $psPath = $env:PSModulePath
    if($psPath.indexOf($userModulesPath) -eq -1) {
        $psPath += ";$userModulesPath"
        $env:PSModulePath = $psPath
        [Environment]::SetEnvironmentVariable("PSModulePath",$psPath, "machine")
    }
    Remove-Module path-utils -ErrorAction SilentlyContinue
    Import-Module path-utils
    Write-Host "path-utils module has been installed." -ForegroundColor Green
}

$scripts["WebPI"] = {
    Write-Host "Installing Web Platform Installer (Web PI)..." -ForegroundColor Cyan
    $msiPath = "$env:USERPROFILE\WebPlatformInstaller_amd64_en-US.msi"
    (New-Object Net.WebClient).DownloadFile('http://go.microsoft.com/fwlink/?LinkID=287166', $msiPath)
    cmd /c start /wait msiexec /i "$msiPath" /q
    del $msiPath
    Write-Host "Web PI installed" -ForegroundColor Green
    $env:path = "$env:ProgramFiles\Microsoft\Web Platform Installer;$env:path"
}

$scripts["7Zip"] = {
    Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
    $msiPath = "$env:USERPROFILE\7z920-x64.msi"
    (New-Object Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z920-x64.msi', $msiPath)
    cmd /c start /wait msiexec /i "$msiPath" /q
    del $msiPath
    Write-Host "7-Zip installed" -ForegroundColor Green
    $env:path = "$env:ProgramFiles\7-Zip;$env:path"
    Add-Path "$env:ProgramFiles\7-Zip"
}

$scripts["SqlServer2014"] = {
    # https://github.com/FeodorFitsner/dacpac-sample/blob/sqlcmd/appveyor.yml
    # http://www.mssqltips.com/sqlservertip/2511/standardize-sql-server-installations-with-configuration-files/
    # https://msdn.microsoft.com/en-us/library/ms144259.aspx
    # %programfiles%\Microsoft SQL Server\120\Setup Bootstrap\Log\
    # HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.SQL2014\MSSQLServer - LoginMode=2 # mixed mode

    Write-Host "Installing SQL Server 2014..." -ForegroundColor Cyan
    $started = (Get-Date)

    $exePath = "$env:USERPROFILE\SQLEXPR_x64_ENU.exe"
    (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/Express%2064BIT/SQLEXPR_x64_ENU.exe', $exePath)
    cmd /c start /wait $exePath /q /ACTION=Install /FEATURES=SQL /INSTANCENAME=$sqlServerInstance /SECURITYMODE=SQL /SAPWD=$sqlServerSaPassword /IACCEPTSQLSERVERLICENSETERMS
    del $exePath
    
    $finished = (Get-Date)
    Write-Host "Elasped time: $((New-TimeSpan –Start $started –End $finished).ToString())"

    Write-Host "SQL Server 2014 installed" -ForegroundColor Green
}

$scripts["Redis"] = {
    Write-Host "Downloading Redis..." -ForegroundColor Cyan
    $redisRoot = "$env:SYSTEMDRIVE\Redis"
    $zipPath = "$($env:USERPROFILE)\redis-2.8.19.zip"
    (New-Object Net.WebClient).DownloadFile('https://github.com/MSOpenTech/redis/releases/download/win-2.8.19/redis-2.8.19.zip', $zipPath)
    7z x $zipPath -y -o"$redisRoot" | Out-Null
    del $zipPath
    Write-Host "Installing Redis as a Windows service..."
    & "$redisRoot\redis-server.exe" --service-install
    Write-Host "Starting Redis service..."
    & "$redisRoot\redis-server.exe" --service-start
    Write-Host "Redis installed" -ForegroundColor Green
}

$scripts["ServiceBus"] = {
    Write-Host "Installing Service Bus 1.1 ..." -ForegroundColor Cyan
    webpicmd /Install /Products:"ServiceBus_1_1" /AcceptEula
    Write-Host "Service Bus installed" -ForegroundColor Green

    Write-Host "Setting up Service Bus..." -ForegroundColor Cyan
    . "$env:ProgramFiles\Service Bus\1.1\Scripts\ImportServiceBusModule.ps1"

    Write-Host "ServiceBus admin user: $serviceBusUsername"
    Write-Host "ServiceBus admin password: (can be seen in Registry under $appveyorInstallRegistryKey)"
    New-LocalUser $serviceBusUsername $serviceBusUserPassword "Service Bus manager"

    Write-Host "Adding Service Bus farm..."
    $sbcert = ConvertTo-SecureString -string $serviceBusUserPassword -force -AsPlainText
    $sbfarm = New-SBFarm –SBFarmDBConnectionString "data source=localhost\$sqlServerInstance;integrated security=true" –CertificateAutoGenerationKey $sbcert -RunAsAccount "$env:ComputerName\$serviceBusUsername"

    Write-Host "Adding Service Bus host..."
    $sbRunAsPassword = ConvertTo-SecureString -AsPlainText -Force -String $serviceBusUserPassword
    $sbhost = Add-SBHost -CertificateAutoGenerationKey $sbcert -SBFarmDBConnectionString "data source=localhost\$sqlServerInstance;integrated security=true" -RunAsPassword $sbRunAsPassword -EnableFirewallRules $true

    Write-Host "Adding Service Bus 'appveyor' namespace..."
    $sbns = New-SBNamespace -Name 'appveyor' -ManageUser $serviceBusUsername
    Write-Host "Service Bus installed and configured" -ForegroundColor Green
}

$scripts["Chocolatey"] = {
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

$scripts["IIS"] = {
    Write-Host "Installing Web Server role..." -ForegroundColor Cyan
    $started = (Get-Date)

    $result = Install-WindowsFeature AS-NET-Framework,Web-Server,Web-WebServer,Web-Default-Doc,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Http-Logging,Web-Http-Tracing,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-AppInit,Web-Asp-Net,Web-Asp-Net45,Web-WebSockets,Web-Mgmt-Console,NET-Framework-45-ASPNET
    
    $finished = (Get-Date)
    Write-Host "Elasped time: $((New-TimeSpan –Start $started –End $finished).ToString())"
    Write-Host "Web Server role and required features installed" -ForegroundColor Green
}

$scripts["Git"] = {
    Write-Host "Installing Git..." -ForegroundColor Cyan
    $exePath = "$env:USERPROFILE\Git-1.9.5-preview20150319.exe"
    (New-Object Net.WebClient).DownloadFile('https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/Git-1.9.5-preview20150319.exe', $exePath)
    cmd /c start /wait $exePath /VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS="icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh" /LOG
    del $exePath
    Add-Path "${env:ProgramFiles(x86)}\Git\cmd"
    $env:path = "${env:ProgramFiles(x86)}\Git\cmd;$env:path"
    Add-Path "${env:ProgramFiles(x86)}\Git\bin"
    $env:path = "${env:ProgramFiles(x86)}\Git\bin;$env:path"
    git config --global core.autocrlf false
    Write-Host "Git installed" -ForegroundColor Green
}

$scripts["Mercurial"] = {
    Write-Host "Installing Mercurial..." -ForegroundColor Cyan
    $exePath = "$env:USERPROFILE\Mercurial-3.3.3-x64.exe"
    (New-Object Net.WebClient).DownloadFile('http://mercurial.selenic.com/release/windows/Mercurial-3.3.3-x64.exe', $exePath)
    cmd /c start /wait $exePath /VERYSILENT
    del $exePath
    Add-Path "$env:ProgramFiles\Mercurial"
    $env:path = "$env:ProgramFiles\Mercurial;$env:path"
    Write-Host "Mercurial installed" -ForegroundColor Green
}

$scripts["Subversion"] = {
    Write-Host "Installing Subversion..." -ForegroundColor Cyan
    $msiPath = "$env:USERPROFILE\Setup-Subversion-1.8.13.msi"
    (New-Object Net.WebClient).DownloadFile('http://sourceforge.net/projects/win32svn/files/1.8.13/Setup-Subversion-1.8.13.msi', $msiPath)
    cmd /c start /wait msiexec /i "$msiPath" /q
    del $msiPath
    Add-Path "${env:ProgramFiles(x86)}\Subversion\bin"
    $env:path = "${env:ProgramFiles(x86)}\Subversion\bin;$env:path"
    svn --version
    Write-Host "Subversion installed" -ForegroundColor Green
}

$scripts["VisualStudio2013"] = {
    Write-Host "Installing Visual Studio 2013 Community ..." -ForegroundColor Cyan
    webpicmd /Install /Products:"VS2013CommunityAzurePack,NETFramework452" /AcceptEula /ForceReboot
    Write-Host "Visual Studio 2013 Community installed" -ForegroundColor Green
}

$scripts["Set_MsBuildPath"] = {
    $msBuild12Path = "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
    $msBuild4Path = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319"
    if(Test-Path $msBuild12Path) {
        Add-Path $msBuild12Path
    } else {
        Add-Path $msBuild4Path
    }
}

$scripts["DotNet452"] = {
    Write-Host "Installing .NET Framework 4.5.2..." -ForegroundColor Cyan
    if(test-path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SKUs\.NETFramework,Version=v4.5.2") {
        Write-Host "Microsoft .Net 4.5.2 Framework is already installed." -ForegroundColor Yellow
        return
    }

    $exePath = "$env:USERPROFILE\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
    (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe', $exePath)
    cmd /c start /wait $exePath /Passive /NoRestart /Log $env:USERPROFILE\net452-install-log.txt
    del $exePath
    Write-Host ".NET Framework 4.5.2 installed" -ForegroundColor Green
}

$scripts["JDK"] = {
    function InstallJDKVersion($javaVersion, $jdk8, $url, $fileName, $jdkPath, $jrePath) {
        Write-Host "Installing $javaVersion..." -ForegroundColor Cyan

        # download
        Write-Host "Downloading installer"
        $exePath = "$env:USERPROFILE\$fileName"
        $logPath = "$env:USERPROFILE\$fileName-install.log"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        $client = New-Object Net.WebClient
        $client.Headers.Add('Cookie', 'gpw_e24=http://www.oracle.com; oraclelicense=accept-securebackup-cookie')
        $client.DownloadFile($url, $exePath)

        # install
        Write-Host "Installing JDK to $jdkPath"
        Write-Host "Installing JRE to $jrePath"

        if($jdk8) {
            $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" INSTALLDIR=`"$jdkPath`" /INSTALLDIRPUBJRE=`"$jrePath`""
        } else {
            $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" /INSTALLDIR=`"$jdkPath`" /INSTALLDIRPUBJRE=`"\`"$jrePath\`"`""
        }
        $proc = [Diagnostics.Process]::Start("cmd.exe", $arguments)
        $proc.WaitForExit()

        # cleanup
        del $exePath
        Write-Host "$javaVersion installed" -ForegroundColor Green
    }

    InstallJDKVersion "JDK 1.7 x86" $false "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-windows-i586.exe" "jdk-7u79-windows-i586.exe" "${env:ProgramFiles(x86)}\Java\jdk1.7.0" "${env:ProgramFiles(x86)}\Java\jre7"
    InstallJDKVersion "JDK 1.7 x64" $false "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-windows-x64.exe" "jdk-7u79-windows-x64.exe" "$env:ProgramFiles\Java\jdk1.7.0" "$env:ProgramFiles\Java\jre7"
    InstallJDKVersion "JDK 1.8 x86" $true "http://download.oracle.com/otn-pub/java/jdk/8u45-b15/jdk-8u45-windows-i586.exe" "jdk-8u45-windows-i586.exe" "${env:ProgramFiles(x86)}\Java\jdk1.8.0" "${env:ProgramFiles(x86)}\Java\jre8"
    InstallJDKVersion "JDK 1.8 x64" $true "http://download.oracle.com/otn-pub/java/jdk/8u45-b15/jdk-8u45-windows-x64.exe" "jdk-8u45-windows-x64.exe" "$env:ProgramFiles\Java\jdk1.8.0" "$env:ProgramFiles\Java\jre8"
}

$scripts["NodeJs"] = {

    $avvmRoot = "$env:SYSTEMDRIVE\avvm\node"

    $nodeVersions = @(
        "0.10.35",
        "0.10.36",
        "0.10.37",
        "0.10.38",
        "0.11.12",
        "0.11.13",
        "0.11.15",
        "0.11.16",
        "0.12.0",
        "0.12.1",
        "0.12.2",
        "0.8.27",
        "0.8.28",
        "1.6.3",
        "1.6.4",
        "1.7.1",
        "1.8.1",
        "2.0.0")

    $nodePlatforms = @(
        "x86",
        "x64"
    )

    $fileTemplates = @{
        "node_x64" = @{
            "files_ps1" = '$files = @{ "nodejs" = "$env:ProgramFiles\nodejs" }'
            "install_ps1" = ''
            "uninstall_ps1" = ''
        }
        "node_x86" = @{
            "files_ps1" = '$files = @{ "nodejs" = "${env:ProgramFiles(x86)}\nodejs" }'
            "install_ps1" = ''
            "uninstall_ps1" = ''
        }
        "iojs_x64" = @{
            "files_ps1" = '$files = @{ "nodejs" = "$env:ProgramFiles\iojs" }'
            "install_ps1" = ''
            "uninstall_ps1" = ''
        }
        "iojs_x86" = @{
            "files_ps1" = '$files = @{ "nodejs" = "${env:ProgramFiles(x86)}\iojs" }'
            "install_ps1" = ''
            "uninstall_ps1" = ''
        }
    }

    function Get-Version([string]$str) {
        $versionDigits = $str.Split('.')
        $version = @{
            major = -1
            minor = -1
            build = -1
            revision = -1
            number = 0
        }

        if($versionDigits.Length -gt 0) {
            $version.major = [int]$versionDigits[0]
        }
        if($versionDigits.Length -gt 1) {
            $version.minor = [int]$versionDigits[1]
        }
        if($versionDigits.Length -gt 2) {
            $version.build = [int]$versionDigits[2]
        }
        if($versionDigits.Length -gt 3) {
            $version.revision = [int]$versionDigits[3]
        }

        for($i = 0; $i -lt $versionDigits.Length; $i++) {
            $version.number += [long]$versionDigits[$i] -shl 16 * (3 - $i)
        }

        return $version
    }

    function ProductName($version) {
        $v = Get-Version $version
        if ($v.Major -eq 0) {
            return 'Node.js'
        } else {
            return 'io.js'
        }
    }

    function ProductInstallDirectory($version, $platform) {
        $v = Get-Version $version
        if($v.Major -eq 0 -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\nodejs"
        } elseif ($v.Major -ge 1 -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\iojs"
        } elseif ($v.Major -eq 0) {
            return "$env:ProgramFiles\nodejs"
        } elseif ($v.Major -ge 1) {
            return "$env:ProgramFiles\iojs"
        }
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
    
        if($v.Major -eq 0 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x86.msi"
        } elseif ($v.Major -ge 1 -and $bitness -eq 'x86') {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x86.msi"
        } elseif ($v.Major -eq 0) {
            $packageUrl = "http://nodejs.org/dist/v$version/x64/node-v$version-x64.msi"
        } elseif ($v.Major -ge 1) {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x64.msi"
        }
    
        $packageFileName = Join-Path ([IO.Path]::GetTempPath()) $packageUrl.Substring($packageUrl.LastIndexOf('/') + 1)
        (New-Object Net.WebClient).DownloadFile($packageUrl, $packageFileName)
        return $packageFileName
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
        if ($v.Major -eq 0) {
            $features = 'NodeRuntime,NodePerfCtrSupport,NodeEtwSupport,npm'
        } else {
            $features = 'NodeRuntime,NodeAlias,NodePerfCtrSupport,NodeEtwSupport,npm' 
        }

        Write-Host "Installing $(ProductName($version)) v$version ($bitness)..."
        $packageFileName = Get-NodeJsInstallPackage $version $bitness
        cmd /c start /wait msiexec /i "$packageFileName" /q "ADDLOCAL=$features"
        del $packageFileName
    }

    function GetUninstallString($productName) {
        $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        return ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
           | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
           | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
           | Select UninstallString).UninstallString.replace('MsiExec.exe /I{', '/x{')
    }

    foreach($nodeVersion in $nodeVersions) {
        foreach($nodePlatform in $nodePlatforms) {
            $nodeName = ProductName $nodeVersion
            Write-Host "Installing $nodeName $nodeVersion $nodePlatform..."

            $avvmDir = "$avvmRoot\$nodeVersion\$nodePlatform"
            $installDir = ProductInstallDirectory $nodeVersion $nodePlatform
            $dirName = [IO.Path]::GetFileName($installDir)
            if(Test-Path $avvmDir) {
                Write-Host "$nodeName $nodeVersion $nodePlatform already installed" -ForegroundColor Gray
                continue
            }

            # create avvm dir
            Write-Host "Creating directory $avvmDir..."
            New-Item $avvmDir -ItemType Directory -Force | Out-Null

            Write-Host "$avvmDir"
            Write-Host "$installDir"
            Write-Host "$dirName"
        }
    }

    #Add-Path "${env:ProgramFiles(x86)}\nodejs"
    #Add-Path "$env:ProgramFiles\nodejs"
    #Add-Path "${env:ProgramFiles(x86)}\iojs"
    #Add-Path "$env:ProgramFiles\iojs"
    #Add-Path "$env:APPDATA\npm"
}

$scripts["NuGet"] = {
    Write-Host "Installing NuGet..." -ForegroundColor Cyan
    $nugetPath = "$env:SYSTEMDRIVE\Tools\NuGet"
    if(-not (Test-Path $nugetPath)) {
        New-Item $nugetPath -ItemType Directory -Force | Out-Null
    }

    (New-Object Net.WebClient).DownloadFile('https://www.nuget.org/nuget.exe', "$nugetPath\NuGet.exe")

    # add support for VS 2013
    $nugetConfig = '<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="Microsoft.Build" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.0.0.0" newVersion="12.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="Microsoft.Build.Engine" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.0.0.0" newVersion="12.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="Microsoft.Build.Framework" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-4.0.0.0" newVersion="12.0.0.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>'
    Set-Content "$nugetPath\NuGet.exe.config" -Value $nugetConfig
    Add-Path $nugetPath
    $env:path = "$nugetPath;$env:path"
    Write-Host "NuGet installed" -ForegroundColor Green
}

$scripts["xUnit192"] = {
    Write-Host "Installing xUnit 1.9.2..." -ForegroundColor Cyan
    $xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit"

    $zipPath = "$($env:USERPROFILE)\xunit-build-1.9.2.zip"
    (New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/xunit-build-1.9.2.zip', $zipPath)
    7z x $zipPath -y -o"$xunitPath" | Out-Null
    del $zipPath

    Add-Path $xunitPath
    $env:path = "$xunitPath;$env:path"
    Write-Host "xUnit 1.9.2 installed" -ForegroundColor Green
}

$scripts["xUnit20"] = {
    Write-Host "Installing xUnit 2.0..." -ForegroundColor Cyan
    $xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit20"
    $tempPath = "$env:USERPROFILE\xunit20"
    nuget install xunit.runner.console -excludeversion -outputdirectory $tempPath

    [IO.Directory]::Move("$tempPath\xunit.runner.console\tools", $xunitPath)
    del $tempPath -Recurse -Force

    [Environment]::SetEnvironmentVariable("xunit20", $xunitPath, "Machine")
    Write-Host "xUnit 2.0 installed" -ForegroundColor Green
}

$scripts["MSpec"] = {
    Write-Host "Installing MSpec..." -ForegroundColor Cyan
    $mspecPath = "$env:SYSTEMDRIVE\Tools\MSpec"
    $tempPath = "$env:USERPROFILE\MSpec"
    nuget install Machine.Specifications.Runner.Console -excludeversion -outputdirectory $tempPath

    [IO.Directory]::Move("$tempPath\Machine.Specifications.Runner.Console\tools", $mspecPath)
    del $tempPath -Recurse -Force

    Add-Path $mspecPath
    $env:path = "$mspecPath;$env:path"
    Write-Host "MSpec installed" -ForegroundColor Green
}

$scripts["VsTestLogger"] = {
    Write-Host "Installing AppVeyor logger for VSTest.Console..." -ForegroundColor Cyan

    $vsTestConsolePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
    if(-not (Test-Path $vsTestConsolePath)) {
        Write-Host "VsTest.Console is not found at $vsTestConsolePath" -ForegroundColor Yellow
        return
    }

    $zipPath = "$($env:USERPROFILE)\Appveyor.MSTestLogger.zip"
    (New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/onprem/Appveyor.MSTestLogger.zip', $zipPath)
    7z x $zipPath -y -o"$vsTestConsolePath\Extensions" | Out-Null
    del $zipPath

    Add-Path $vsTestConsolePath
    $env:path = "$vsTestConsolePath;$env:path"
    Write-Host "AppVeyor VSTest.Console logger installed" -ForegroundColor Green
}

$scripts["NUnit"] = {
    Write-Host "Installing NUnit 2.6.4..." -ForegroundColor Cyan
    $toolsPath = "$env:SYSTEMDRIVE\Tools"
    $nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit"

    # nunit
    $zipPath = "$($env:USERPROFILE)\NUnit-2.6.4.zip"
    (New-Object Net.WebClient).DownloadFile('http://github.com/nunit/nunitv2/releases/download/2.6.4/NUnit-2.6.4.zip', $zipPath)
    7z x $zipPath -y -o"$toolsPath" | Out-Null
    del $zipPath
    [IO.Directory]::Move("$toolsPath\NUnit-2.6.4", $nunitPath)

    # logger
    $zipPath = "$($env:USERPROFILE)\Appveyor.NUnitLogger.zip"
    (New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/onprem/Appveyor.NUnitLogger.zip', $zipPath)
    7z x $zipPath -y -o"$nunitPath\bin\addins" | Out-Null
    del $zipPath

    Add-Path "$nunitPath\bin"
    $env:path = "$nunitPath\bin;$env:path"
    Write-Host "NUnit installed" -ForegroundColor Green
}

$scripts["AppveyorDatabase"] = {
    Write-Host "Creatig AppVeyor SQL database..." -ForegroundColor Cyan

    Write-Host "AppVeyor SQL username: $appveyorDatabaseUserName"
    Write-Host "AppVeyor SQL password: (can be seen in Registry under $appveyorInstallRegistryKey)"

    # master database
    Write-Host "Connecting to 'master' database..."
    $connectionString = "Server=(local)\$sqlServerInstance;Database=master;Integrated security=true;"
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()

    # create new database
    Write-Host "Creating '$appveyorDatabaseName' database..."
    $cmd = New-Object System.Data.SqlClient.SqlCommand("CREATE DATABASE $appveyorDatabaseName", $conn)
    $result = $cmd.ExecuteNonQuery()

    # create login
    Write-Host "Creating '$appveyorDatabaseUserName' login..."
    $escapedPassword = $appveyorDatabaseUserPassword.Replace("'", "''")
    $cmd = New-Object System.Data.SqlClient.SqlCommand("CREATE LOGIN $appveyorDatabaseUserName WITH PASSWORD='$escapedPassword'", $conn)
    $result = $cmd.ExecuteNonQuery()
    
    $conn.Close()

    # appveyor database
    Write-Host "Connecting to '$appveyorDatabaseName' database..."
    $connectionString = "Server=(local)\$sqlServerInstance;Database=$appveyorDatabaseName;Integrated security=true;"
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()

    # create database user
    Write-Host "Creating database user..."
    $cmd = New-Object System.Data.SqlClient.SqlCommand("CREATE USER $appveyorDatabaseUserName FROM LOGIN $appveyorDatabaseUserName", $conn)
    $result = $cmd.ExecuteNonQuery()

    Write-Host "Assigning user to db_owner..."
    $cmd = New-Object System.Data.SqlClient.SqlCommand("EXEC sp_addrolemember 'db_owner', '$appveyorDatabaseUserName'", $conn)
    $result = $cmd.ExecuteNonQuery()

    $conn.Close()
    Write-Host "AppVeyor database created" -ForegroundColor Green
}

function Set-AppveyorCommonConfigurationSettings {
    # system settings
    $appUrl = "http://$env:COMPUTERNAME"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.OnPremise" -Value 'true'
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.InternalApplicationUrl" -Value $appUrl
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.AuthorizationToken" -Value $appveyorAuthorizationToken
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.JobDetailsInCloudStorage" -Value "false"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.BuildWorkerStartJobTimeout" -Value "120"

    # database connection string
    $connectionString = "Server=(local)\$sqlServerInstance;Database=$appveyorDatabaseName;User ID=$appveyorDatabaseUserName;Password=$appveyorDatabaseUserPassword"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Database.ConnectionString" -Value $connectionString

    # Service Bus
    #Endpoint=sb://feodor-pc/DemoSB;StsEndpoint=https://feodor-pc:9355/DemoSB;RuntimePort=9354;ManagementPort=9355;WindowsUsername=sbuser;WindowsDomain=FEODOR-PC;WindowsPassword=Password12!
    $sbConnectionString = "Endpoint=sb://$env:COMPUTERNAME/appveyor;StsEndpoint=https://$($env:COMPUTERNAME):9355/appveyor;RuntimePort=9354;ManagementPort=9355;WindowsUsername=$serviceBusUsername;WindowsDomain=$env:COMPUTERNAME;WindowsPassword=$serviceBusUserPassword"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Messaging.ServiceBusConnectionString" -Value $sbConnectionString
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Messaging.ScheduleJobsQueueName" -Value "scheduler"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Messaging.BuildManagerQueueName" -Value "build-manager"

    # security
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Security.MasterKey" -Value $appveyorSecurityMasterKey

    # VSO
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Vso.GlobalUrl" -Value "https://app.vssps.visualstudio.com/"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Vso.AccountApiUrl" -Value "https://{0}.visualstudio.com/DefaultCollection/_apis/"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Vso.Scope" -Value "preview_api_all preview_msdn_licensing"

    # redis settings
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Redis.ServerName" -Value $redisServer
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Redis.Port" -Value $redisPort
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Redis.Password" -Value ""
}

$scripts["AppveyorWeb"] = {
    Write-Host "Installing AppVeyor Web..." -ForegroundColor Cyan

    Write-Host "Downloading and unpacking files..."
    $zipPath = "$($env:USERPROFILE)\Appveyor.Web.zip"
    (New-Object Net.WebClient).DownloadFile($appveyorWebUrl, $zipPath)
    7z x $zipPath -y -o"$appveyorWebPath" | Out-Null
    del $zipPath

    if(-not (Test-Path $appveyorServerRegistryKey)) {
        Write-Host "Creating settings Registry key..."
        New-Item $appveyorServerRegistryKey -Force | Out-Null
    }

    # common settings
    Set-AppveyorCommonConfigurationSettings

    # Web-specific settings
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Messaging.Redis.EventKey" -Value "AppVeyor.Web"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "Analytics.TrackingID" -Value $googleAnalyticsId

    # Create EventLog
    Write-Host "Creating Event Log and Source..."
    New-EventLog -LogName 'AppVeyor' -Source 'AppVeyor Web' -ErrorAction SilentlyContinue

    # update default web site
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager
    if($serverManager -ne $null)
    {
        # find 'Default Web Site'
        $site = $serverManager.Sites | where { $_.Id -eq 1 }
        if($site -ne $null)
        {
            Write-Host "Updating root of 'Default Web Site'"
            
            # change physical path
            $rootApp = $site.Applications | where { $_.Path -eq "/" }
            $rootVdir = $rootApp.VirtualDirectories | where { $_.Path -eq "/" }
            $rootVdir.PhysicalPath = $appveyorWebPath
            $serverManager.CommitChanges()

            # create Artifacts folder
            if(-not (Test-Path $appveyorArtifactsStoragePath)) {
                Write-Host "Creating artifacts storage directory $appveyorArtifactsStoragePath"
                New-Item $appveyorArtifactsStoragePath -ItemType Directory -Force | Out-Null
            }
            # modify folder permissions
            $appPoolName = $rootApp.ApplicationPoolName
            $appPoolIdentity = "IIS APPPOOL\$appPoolName"
            Write-Host "Add 'modify' permissions for $appPoolIdentity to $appveyorArtifactsStoragePath"

            icacls $appveyorArtifactsStoragePath /grant ($appPoolIdentity + ':(OI)(CI)(M)')
        } else {
            Write-Host "Default Web Site with ID 1 was not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Microsoft.Web.Administration.ServerManager was not created" -ForegroundColor Yellow
    }

    Write-Host "AppVeyor Web installed" -ForegroundColor Green
}

$scripts["AppveyorWorker"] = {
    Write-Host "Installing AppVeyor Worker..." -ForegroundColor Cyan

    $svc = (Get-Service 'Appveyor.Worker' -ErrorAction SilentlyContinue)
    if($svc -and $svc.Status -eq 'Running') {
        Write-Host "Stopping AppVeyor.Worker service..."
        Stop-Service 'Appveyor.Worker'
    }

    Write-Host "Downloading and unpacking files..."
    $zipPath = "$($env:USERPROFILE)\Appveyor.Worker.zip"
    (New-Object Net.WebClient).DownloadFile($appveyorWorkerUrl, $zipPath)
    7z x $zipPath -y -o"$appveyorWorkerPath" | Out-Null
    del $zipPath

    if(-not (Test-Path $appveyorServerRegistryKey)) {
        New-Item $appveyorServerRegistryKey -Force | Out-Null
    }


    # common settings
    Set-AppveyorCommonConfigurationSettings

    # Worker-specific settings
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.BuildWorkerProvisioningTimeout" -Value "5"
    Set-ItemProperty -Path $appveyorServerRegistryKey -Name "System.WorkerQueueTimeout" -Value "1"

    # should we create service?
    if(-not $svc) {
        # create service
        $svc = New-Service -Name 'Appveyor.Worker' -DisplayName 'AppVeyor Worker' -Description 'Background worker running AppVeyor business logic' `
            -BinaryPathName "$appveyorWorkerPath\Appveyor.Worker.Service.exe" -StartupType Automatic `
            -DependsOn 'Service Bus Gateway','Service Bus Message Broker','Service Bus Resource Provider'
    }
    
    Write-Host "Starting Appveyor.Worker service..."
    Start-Service 'Appveyor.Worker'

    Write-Host "AppVeyor Web installed" -ForegroundColor Green
}

$scripts["AppveyorBuildAgent"] = {
    Write-Host "Installing AppVeyor Build Agent..." -ForegroundColor Cyan

    $svc = (Get-Service 'Appveyor.BuildAgent' -ErrorAction SilentlyContinue)
    if($svc -and $svc.Status -eq 'Running') {
        Write-Host "Stopping AppVeyor.BuildAgent service..."
        Stop-Service 'Appveyor.BuildAgent'
    }

    Write-Host "Downloading and unpacking files..."
    $zipPath = "$($env:USERPROFILE)\Appveyor.BuildAgent.zip"
    (New-Object Net.WebClient).DownloadFile($appveyorBuildAgentUrl, $zipPath)
    7z x $zipPath -y -o"$appveyorBuildAgentPath" | Out-Null
    del $zipPath

    if(-not (Test-Path $appveyorBuildAgentRegistryKey)) {
        New-Item $appveyorBuildAgentRegistryKey -Force | Out-Null
    }

    # BuildAgent-specific settings
    $appUrl = "http://$env:COMPUTERNAME"
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "ApplicationUrl" -Value $appUrl
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "DeleteBuildFolderOnFinish" -Value "true"
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "MaxConcurrentJobs" -Value 10
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "Mode" -Value "OnPremise"
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "ProjectsDirectory" -Value "$env:SYSTEMDRIVE\Projects"
    Set-ItemProperty -Path $appveyorBuildAgentRegistryKey -Name "WorkersQueueName" -Value "on-premise"

    # should we create service?
    if(-not $svc) {
        
        # request current use credentials
        $svcUsername = "$env:COMPUTERNAME\$env:USERNAME"
        $svCred = Get-Credential -UserName $svcUsername -Message "Please enter '$env:USERNAME' account password. AppVeyor Build Agent will run under that user."

        if($svCred) {
            Write-Host "Set Logon As A Service right to '$svcUsername' user"
            Grant-LogonAsService $svcUsername
        }

        # add service
        $svc = New-Service -Name 'Appveyor.BuildAgent' -DisplayName 'AppVeyor Build Agent' -Description 'Background worker running AppVeyor builds' `
            -BinaryPathName "$appveyorBuildAgentPath\Appveyor.BuildAgent.Service.exe" -StartupType Automatic `
            -Credential $svCred
    }

    # add modules directory to PSModulePath
    $agentModulesPath = "$appveyorBuildAgentPath\Modules"
    $psPath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
    if($psPath.indexOf($agentModulesPath) -eq -1) {
        $psPath += ";$agentModulesPath"
        [Environment]::SetEnvironmentVariable("PSModulePath",$psPath, "Machine")
    }
    
    Write-Host "Starting Appveyor.BuildAgent service..."
    Start-Service 'Appveyor.BuildAgent'

    Write-Host "AppVeyor Build Agent installed" -ForegroundColor Green
}

# Prerequisites
#Invoke-InitialSystemSetup
#Install-PathUtils
#Install-WebPI
#Install-Chocolatey
#Install-7Zip
#Install-SqlServer2014
#Install-Redis
#Install-IIS
#Install-Git
#Install-Mercurial
#Install-Subversion
#Install-VisualStudio2013
#Set-MsBuildPath

# AppVeyor
#Install-ServiceBus
#New-AppveyorDatabase
#Install-AppveyorWeb
#Install-AppveyorWorker
#Install-AppveyorBuildAgent

# testing frameworks
#Install-NuGet
#Install-xUnit192
#Install-xUnit20
#Install-VsTestLogger
#Install-NUnit
#Install-MSpec

# additional software/SDKs
#Install-JDK
#Install-NodeJs

<#
 Installation Scenarios

 1. AppVeyor All-in-One (clean machine)

 2. AppVeyor Service (Web and Worker)
    .NET 4.5.2
    SQL Server
    Redis
    IIS
    Service Bus
    AppVeyor Database
    AppVeyor Web
    AppVeyor Worker

 3. AppVeyor Build Agent
    .NET 4.5.2
    AppVeyor Build Agent
    Source controls
      | Git
      | Mercurial
      | Subversion
    NuGet
    xUnit192
    xUnit20
    VsTestLogger (if VS installed)
    NUnit
    MSpec
      
 4. Stacks/Languages
      Visual Studio 2013 CE
      NodeJs
      JDK
      Ruby
      Python


Install-AppVeyor

Install-AppVeyor -Roles Web,Worker -Version 1.2.0
Install-AppVeyor -Roles BuildAgent

Update-AppVeyor -Roles BuildAgent -Version 1.3.0
Uninstall-AppVeyor -Roles Worker

Install-AppVeyor -Scenario AllInOne

#>

function Install-AppVeyor {
    Write-Host "Install AppVeyor role(s)" -ForegroundColor Gray
}

function Update-AppVeyor {
    Write-Host "Update AppVeyor role(s)" -ForegroundColor Gray
}

function Uninstall-AppVeyor {
    Write-Host "Uninstall AppVeyor role(s)" -ForegroundColor Gray
}

Export-ModuleMember -Function Install-AppVeyor,Update-AppVeyor,Uninstall-AppVeyor