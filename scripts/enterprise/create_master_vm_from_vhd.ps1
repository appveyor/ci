$creds = Get-Credential -Message "Please enter `"Client ID`" as username and `"Client Sercret`" as password"
$tenantID = Read-Host "Tenant ID"
$subscriptionID = Read-Host "Subscription ID"
$resourceGroupName = Read-Host "Resource group"
$masterVmName = Read-Host "Master VM name"
$masterVmSize = Read-Host "Master VM size, e.g. `"Standard_DS2_V2`""
$osDiskUri = Read-Host "Master VHD URI"
$virtualNetworkName = Read-Host "Virtual network"
$locationName = Read-Host "Location"

# login
Write-Host "Logging into Azure RM"
Login-AzureRmAccount -Credential $creds -ServicePrincipal -TenantId $tenantID

# select subscription
Write-Host "Selecting subscription"
Get-AzureRmSubscription -SubscriptionId $subscriptionID | Select-AzureRmSubscription

# create VM
$publicIpAddressName = "$masterVmName-ip"
$nicName = "$masterVmName-nic"
Write-Host "Getting virtual network details"
$virtualNetwork = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName

Write-Host "Creating new public IP"
$publicIp = New-AzureRmPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $locationName -AllocationMethod Dynamic

Write-Host "Creating new network interface"
$nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -Location $locationName -SubnetId $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIp.Id

Write-Host "Configuring VM"
$vmConfig = New-AzureRmVMConfig -VMName $masterVmName -VMSize $masterVmSize
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $masterVmName -VhdUri $osDiskUri -CreateOption Attach -Windows
$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

Write-Host "Creating VM..."
$vm = New-AzureRmVM -VM $vmConfig -Location $locationName -ResourceGroupName $resourceGroupName

Write-Host "VM created" -ForegroundColor Green