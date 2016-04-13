# Proxy addresses
$proxies = @{
    "146.148.85.29" = "10.240.0.88"   # a
    "104.197.145.181" = "10.240.0.2"  # b
    "104.197.110.30" = "10.240.0.21"  # c
    "104.197.65.101" = "10.240.0.74"  # f
}

Write-Host -NoNewline "Enabling AppVeyor HTTP proxy..."

# get external IP
$ip = (New-Object Net.WebClient).DownloadString('https://www.appveyor.com/tools/my-ip.aspx').Trim()

$proxy_ip = $proxies[$ip]
$proxy_port = "8888"

if(-not $proxy_ip) {
    # IP address not found
    # no proxy for the given address
    Write-Host "Skipped - no proxy found for the current build worker" -ForegroundColor Yellow
    return
}

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f | out-null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "$proxy_ip`:$proxy_port" /f | out-null

# notifying wininet
$source=@"

[DllImport("wininet.dll")]

public static extern bool InternetSetOption(int hInternet, int dwOption, int lpBuffer, int dwBufferLength);  

"@

#Create type from source
$wininet = Add-Type -memberDefinition $source -passthru -name InternetSettings

#INTERNET_OPTION_PROXY_SETTINGS_CHANGED
$wininet::InternetSetOption([IntPtr]::Zero, 95, [IntPtr]::Zero, 0)|out-null

#INTERNET_OPTION_REFRESH
$wininet::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0)|out-null

# save proxy details in environment variables
$env:APPVEYOR_HTTP_PROXY_IP = $proxy_ip
$env:APPVEYOR_HTTP_PROXY_PORT = $proxy_port

Write-Host "OK" -ForegroundColor Green
