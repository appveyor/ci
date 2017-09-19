#Reason to create callme.ps1 file is to make script copy-paste-able to PS window and still be able to ask for password

'
$storageAccountName = Read-Host "Please enter source Storage Account Name"

$secureStr = Read-Host "Please enter source Storage Account Access Key" -AsSecureString 
#http://stackoverflow.com/questions/21741803/powershell-securestring-encrypt-decrypt-to-plain-text-not-working
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStr)
$storageAccountKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$destinationStorageAccountName = Read-Host "Press Enter to use the same storage account as destination, or type destination storage account name here"
if ($destinationStorageAccountName) {
    $secureStr = Read-Host "Please enter destination Storage Account Access Key" -AsSecureString 
    #http://stackoverflow.com/questions/21741803/powershell-securestring-encrypt-decrypt-to-plain-text-not-working
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStr)
    $destinationAccountKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

$srcBlobUri = Read-Host "Please enter source VHD URI"

$destContainer = Read-Host "Please enter destination container name or press Enter for default (images)"
if (!$destContainer) {$destContainer = "images"}

$destBlobDefault = "master-" + (Get-Date -Format "yyyy-MM-dd") + ".vhd"
$destBlob = Read-Host "Please enter target master VHD blob name press Enter for default ($destBlobDefault)"
if (!$destBlob) {$destBlob = $destBlobDefault}

# copy master blob to images
$sourceStorageContext = New-AzureStorageContext `
    -StorageAccountName $storageAccountName `
    -StorageAccountKey $storageAccountKey
 
if ($destinationStorageAccountName) {
 
    $destinationStorageContext = New-AzureStorageContext `
        -StorageAccountName $destinationStorageAccountName `
        -StorageAccountKey $destinationAccountKey
}
else {
    $destinationStorageContext = $sourceStorageContext
}

$destContainerExist = Get-AzureStorageContainer -Name $destContainer -Context $destinationStorageContext -ErrorAction SilentlyContinue
if (!$destContainerExist) {
    Write-Host "`nContainer $destContainer does not exist in $storageAccountName storage account, creating..." -ForegroundColor Yellow
    New-AzureStorageContainer -Name $destContainer -Context $destinationStorageContext
}

$vhdBlob = Start-AzureStorageBlobCopy `
    -AbsoluteUri $srcBlobUri `
    -DestContainer $destContainer `
    -DestBlob $destBlob `
    -DestContext $destinationStorageContext

Get-AzureStorageBlobCopyState -Blob $destBlob -Container $destContainer -Context $destinationStorageContext

# clear after itself
del .\callme.ps1
' > callme.ps1

.\callme.ps1
