
# Install-Module -Name Az.Security -Force
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

$reportFileName = 'Report.csv'
if (Test-Path $reportFileName) {
    Remove-Item $reportFileName
}

$subscriptionList | foreach {
    Set-AzContext -SubscriptionId $_.subscriptionId
    $subscriptionId = $_.subscriptionId
    $subscriptionName = $_.subscriptionName

    $pricingList += Get-AzSecurityPricing | foreach {
        New-Object PSObject -prop @{
            subscriptionName = $subscriptionName;
            subscriptionId = $subscriptionId;
            pricingItemName = $_.name;
            pricingItemId = $_.id
            pricingTier = $_.PricingTier
            timeRemaining = $_.FreeTrialRemainingTime
        } 

    }
}

Add-Content -Path $reportFileName  -Value '"Subscription Name","Subscription Id","Item Name"," Item Id","Pricing Tier","Time Remaining"'
$pricingList | foreach { 
    $temp = $_.subscriptionName + "," + $_.subscriptionId + "," + $_.pricingItemName + "," + $_.pricingItemId + "," + $_.pricingTier+ "," + $_.timeRemaining
    Add-Content -Path  Report.csv -Value  $temp
}