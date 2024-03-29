#Connect to an Azure Account
#   Connect-AzAccount

#Provide the subscription Id where the VMs reside
$subscriptionId = "079fed67-2834-4fc9-bc04-3bdd5fd11228"
$costStartDate = "2020-06-01"
$costEndDate = "2020-06-30"

#Provide the name of the csv file to be exported
$reportName = "virtualMachines.csv"

Select-AzSubscription $subscriptionId
$report = @()
$vms = Get-AzVM -Status
$publicIps = Get-AzPublicIpAddress 
$costs = Get-AzConsumptionUsageDetail -StartDate $costStartDate -EndDate $costEndDate
$nics = Get-AzNetworkInterface | ?{ $_.VirtualMachine -NE $null} 
foreach ($nic in $nics) { 
    $info = "" | Select VmName, ResourceGroupName, Region, VmSize, Status, ComputeCost, VirturalNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress 
    $vm = $vms | ? -Property Id -eq $nic.VirtualMachine.id 
    $vmCost = $costs | ? -Property InstanceId -eq $nic.VirtualMachine.id
    foreach($publicIp in $publicIps) { 
        if($nic.IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
            $info.PublicIPAddress = $publicIp.ipaddress
            } 
        } 
    $info.OsType = $vm.StorageProfile.OsDisk.OsType 
    $info.VMName = $vm.Name 
    $info.ResourceGroupName = $vm.ResourceGroupName 
    $info.Region = $vm.Location 
    $info.VmSize = $vm.HardwareProfile.VmSize
    $info.Status = $vm.PowerState

    $info.ComputeCost = 0.0
    if ($vmCost.length -gt 0) {
        foreach ($k in $vmCost) {
            $info.ComputeCost += $k.PretaxCost
        }
    } 
    #$info.ComputeCost = $vmCost[0].PretaxCost
    $info.VirturalNetwork = $nic.IpConfigurations.subnet.Id.Split("/")[-3] 
    $info.Subnet = $nic.IpConfigurations.subnet.Id.Split("/")[-1] 
    $info.PrivateIpAddress = $nic.IpConfigurations.PrivateIpAddress 
    $report+=$info 
} 
$report | ft VmName, ResourceGroupName, Region, VmSize, Status, ComputeCost, VirturalNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress 
$report | Export-CSV "$home/$reportName"