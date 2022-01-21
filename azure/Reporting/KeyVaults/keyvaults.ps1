#$subscription = "d6ec19c6-066b-4041-ac2a-99a305810922"
#Login-AzAccount
#Set-AzContext -SubscriptionId $subscription

$subscriptionList = Get-AzSubscription | foreach {
    New-Object PSObject -prop @{
        subscriptionId = $_.id;
        subscriptionName = $_.name
        tenantId = $_.tenantId
    } 
}
Write-Host $subscriptionList

$subscriptionList | foreach {
    Set-AzContext -SubscriptionId $_.subscriptionId
    $subscriptionId = $_.subscriptionId
    $subscriptionName = $_.subscriptionName
       
       $storageaccountList += Get-AzStorageAccount | foreach {
        New-Object PSObject -prop @{
              subscriptionName = $subscriptionName
              subscriptionId = $subscriptionId
        
            storageaccountresourceGroupName = $_.ResourceGroupName
            storageAccount= $_.StorageAccountName
        }
    }
}
Write-Host $storageaccountList

$storageaccountList | foreach {
    Set-AzContext -SubscriptionId $_.subscriptionId

    $subscriptionId = $_.subscriptionId
    $subscriptionName = $_.subscriptionName
    $storageaccountresourceGroupName = $_.storageaccountresourceGroupName
    $storageAccount= $_.storageAccountName
    
    Write-Host "RG Name"
    Write-Host $storageaccountresourceGroupName
    $keyvaultList += Get-AzKeyVault -resourcegroup $storageaccountresourceGroupName -name '*'| foreach {
        Write-Host "In Keyvault loop"
        Write-Host $_
         New-Object PSObject -prop @{
            Keyvaultname = $_.keyVaultName
            keyvaultresourceGroupName = $_.resourceGroupName 
            subscriptionName = $subscriptionName
            subscriptionId = $subscriptionId
            storageaccountresourceGroupName = $storageaccountresourceGroupName
            storageAccount= $storageAccount
         }
    }
}
Write-Host $keyvaultList
