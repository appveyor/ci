function Get-IPs {

        Param(
        [Parameter(Mandatory = $true)]
        [array] $Subnets
        )

foreach ($subnet in $subnets)
    {
        #Split IP and subnet
        $IP = ($Subnet -split "\/")[0]
        $SubnetBits = ($Subnet -split "\/")[1]
        if ($SubnetBits -eq "32") {
            $IP
        } else {
            #Convert IP into binary
            #Split IP into different octects and for each one, figure out the binary with leading zeros and add to the total
            $Octets = $IP -split "\."
            $IPInBinary = @()
            foreach($Octet in $Octets)
                {
                    #convert to binary
                    $OctetInBinary = [convert]::ToString($Octet,2)

                    #get length of binary string add leading zeros to make octet
                    $OctetInBinary = ("0" * (8 - ($OctetInBinary).Length) + $OctetInBinary)

                    $IPInBinary = $IPInBinary + $OctetInBinary
                }
            $IPInBinary = $IPInBinary -join ""

            #Get network ID by subtracting subnet mask
            $HostBits = 32-$SubnetBits
            $NetworkIDInBinary = $IPInBinary.Substring(0,$SubnetBits)

            #Get host ID and get the first host ID by converting all 1s into 0s
            $HostIDInBinary = $IPInBinary.Substring($SubnetBits,$HostBits)
            $HostIDInBinary = $HostIDInBinary -replace "1","0"

            #Work out all the host IDs in that subnet by cycling through $i from 1 up to max $HostIDInBinary (i.e. 1s stringed up to $HostBits)
            #Work out max $HostIDInBinary
            $imax = [convert]::ToInt32(("1" * $HostBits),2) -1

            $IPs = @()

            #Next ID is first network ID converted to decimal plus $i then converted to binary
            For ($i = 1 ; $i -le $imax ; $i++)
                {
                    #Convert to decimal and add $i
                    $NextHostIDInDecimal = ([convert]::ToInt32($HostIDInBinary,2) + $i)
                    #Convert back to binary
                    $NextHostIDInBinary = [convert]::ToString($NextHostIDInDecimal,2)
                    #Add leading zeros
                    #Number of zeros to add
                    $NoOfZerosToAdd = $HostIDInBinary.Length - $NextHostIDInBinary.Length
                    $NextHostIDInBinary = ("0" * $NoOfZerosToAdd) + $NextHostIDInBinary

                    #Work out next IP
                    #Add networkID to hostID
                    $NextIPInBinary = $NetworkIDInBinary + $NextHostIDInBinary
                    #Split into octets and separate by . then join
                    $IP = @()
                    For ($x = 1 ; $x -le 4 ; $x++)
                        {
                            #Work out start character position
                            $StartCharNumber = ($x-1)*8
                            #Get octet in binary
                            $IPOctetInBinary = $NextIPInBinary.Substring($StartCharNumber,8)
                            #Convert octet into decimal
                            $IPOctetInDecimal = [convert]::ToInt32($IPOctetInBinary,2)
                            #Add octet to IP
                            $IP += $IPOctetInDecimal
                        }

                    #Separate by .
                    $IP = $IP -join "."
                    $IPs += $IP
                }
            $IPs
        }
    }
}


Write-Host "Adding SSH known hosts..." -ForegroundColor Cyan
$sshPath = Join-Path $Home ".ssh"
if(-not (Test-Path $sshPath)) {
    New-Item $sshPath -ItemType directory -Force
}

$contents = @()
# GitHub IP addresses

$GIthubIPs="192.30.252.0/22",
    "185.199.108.0/22",
    "13.229.188.59/32",
    "13.250.177.223/32",
    "18.194.104.89/32",
    "18.195.85.27/32",
    "35.159.8.160/32",
    "52.74.223.119/32"
Get-IPs -subnets $GIthubIPs | ForEach-Object {
    $contents += "github.com,$_ ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="
}

# BitBucket
$BitBucketIPs="104.192.143.1",
    "104.192.143.2",
    "104.192.143.3",
    "104.192.143.65",
    "104.192.143.66",
    "104.192.143.67"
$BitBucketIPs | ForEach-Object {
    $contents += "bitbucket.org,$_ ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw=="
}

$knownhostfile = Join-Path $sshPath "known_hosts"
[IO.File]::WriteAllLines($knownhostfile, $contents)

Write-Host "Known hosts configured" -ForegroundColor Green
