#Reason to create callme.ps1 file is to make script copy-paste-able to PS windows and still be able to ask for password

'
$storageAccountName = Read-Host "Please enter Storage Account Name"

$secureStr = Read-Host "Please enter Storage Account Access Key" -AsSecureString 
#http://stackoverflow.com/questions/21741803/powershell-securestring-encrypt-decrypt-to-plain-text-not-working
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStr)
$storageAccountKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$srcContainer = "vhds"
$srcBlob = Read-Host "Please enter source VHD blob name"

$destContainer = Read-Host "Please enter destination container name or press Enter for default (images)"
if (!$destContainer) {$destContainer = "images"}

$destBlobDefault = "master" + (Get-Date -Format "yyyy-MM-dd") + ".vhd"
$destBlob = Read-Host "Please enter target master VHD blob name press Enter for default ($destBlobDefault)"
if (!$destBlob) {$destBlob = $destBlobDefault}

# copy master blob to images
$storageContext = New-AzureStorageContext `
    –StorageAccountName $storageAccountName `
    -StorageAccountKey $storageAccountKey

$destContainerExist = Get-AzureStorageContainer -Name $destContainer -Context $storageContext -ErrorAction SilentlyContinue
if (!$destContainerExist) {
  Write-Host "`nContainer $destContainer does not exist in $storageAccountName storage account, creating..." -ForegroundColor Yellow
  New-AzureStorageContainer -Name $destContainer -Context $storageContext
}

$vhdBlob = Start-AzureStorageBlobCopy `
    -SrcContainer $srcContainer `
    -SrcBlob $srcBlob `
    -SrcContext $storageContext `
    -DestContainer $destContainer `
    -DestBlob $destBlob `
    -DestContext $storageContext

Get-AzureStorageBlobCopyState -Blob $destBlob -Container $destContainer -Context $storageContext

# clear after itself
del .\callme.ps1
' > callme.ps1

.\callme.ps1
