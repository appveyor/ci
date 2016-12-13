$storageContext = New-AzureStorageContext `
    –StorageAccountName '<account-name>' `
    -StorageAccountKey '<account-key>'

# copy master to images
$srcContainer = 'vhds'
$srcBlob = 'master.vhd'

$destContainer = 'images'
$destBlob = 'master-2016-12-12.vhd'

# copy blob
$vhdBlob = Start-AzureStorageBlobCopy `
    -SrcContainer $srcContainer `
    -SrcBlob $srcBlob `
    -SrcContext $storageContext `
    -DestContainer $destContainer `
    -DestBlob $destBlob `
    -DestContext $storageContext

Get-AzureStorageBlobCopyState -Blob $destBlob -Container $destContainer -Context $storageContext