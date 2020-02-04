#$subscription = "d6ec19c6-066b-4041-ac2a-99a305810922"
#Login-AzAccount
#Set-AzContext -SubscriptionId $subscription

$csvFileName = $Args[0]
$nsgList = Import-Csv $csvFileName | foreach {
    New-Object PSObject -prop @{
      RgName = $_.RgName;
      NsgName = $_.NsgName
      SubnetCIDR = $_.SubnetCIDR
    }
    
  }
$nsgList
$nsgList | foreach {
  write-Host "Processing" $_.NsgName
  $nsg = Get-AzNetworkSecurityGroup -Name $_.NsgName -ResourceGroupName $_.RgName
  $nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-Intra-Subnet-Inbound" -Description "Allows VMs within the subnet to communicate freely" -Access Allow `
    -Protocol * -Direction Inbound -Priority 4095 -SourceAddressPrefix $_.SubnetCIDR -SourcePortRange * `
    -DestinationAddressPrefix $_.SubnetCIDR -DestinationPortRange *
  $nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-Intra-Subnet-Outbound" -Description "Allows VMs within the subnet to communicate freely" -Access Allow `
    -Protocol * -Direction Outbound -Priority 4095 -SourceAddressPrefix $_.SubnetCIDR -SourcePortRange * `
    -DestinationAddressPrefix $_.SubnetCIDR -DestinationPortRange *
  $nsg | Set-AzNetworkSecurityGroup
}