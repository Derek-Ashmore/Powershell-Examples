#Connect to an Azure Account
#   Connect-AzAccount

#Provide the subscription Id where the VMs reside
$subscriptionId = "079fed67-2834-4fc9-bc04-3bdd5fd11228"
$costStartDate = "2020-06-01"
$costEndDate = "2020-06-30"

#Provide the name of the csv file to be exported
$reportName = "virtualMachineOpenPorts.csv"

function clone($obj)
{
    $newobj = New-Object PsObject
    $obj.psobject.Properties | % {Add-Member -MemberType NoteProperty -InputObject $newobj -Name $_.Name -Value $_.Value}
    return $newobj
}

Select-AzSubscription $subscriptionId
$report = @()
$vms = Get-AzVM -Status
$publicIps = Get-AzPublicIpAddress
$nics = Get-AzNetworkInterface | ?{ $_.VirtualMachine -NE $null} 
$nsgs = Get-AzNetworkSecurityGroup                                                                                                                       
foreach ($nic in $nics) { 
    $info = "" | Select VmName, ResourceGroupName, Region, VmSize, OsType, PublicIPAddress, Status, VirturalNetwork, Subnet, NsgName, OpenPort, Priority, Protocol, Source
    $vm = $vms | ? -Property Id -eq $nic.VirtualMachine.id 
    $info.OsType = $vm.StorageProfile.OsDisk.OsType 
    $info.VMName = $vm.Name 
    $info.ResourceGroupName = $vm.ResourceGroupName 
    $info.Region = $vm.Location 
    $info.VmSize = $vm.HardwareProfile.VmSize
    $info.Status = $vm.PowerState

    foreach($publicIp in $publicIps) { 
        if($nic.IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
            $info.PublicIPAddress = $publicIp.ipaddress
        } 
    } 

    $info.VirturalNetwork = $nic.IpConfigurations.subnet.Id.Split("/")[-3] 
    $info.Subnet = $nic.IpConfigurations.subnet.Id.Split("/")[-1] 

    if ($nic.NetworkSecurityGroup -ne $null) {
        $nsgId = $nic.NetworkSecurityGroup.Id
    } else {
        #Write-Host "SubnetId:" $nic.IpConfigurations[0].subnet.Id
        $subnet = Get-AzVirtualNetworkSubnetConfig -ResourceId $nic.IpConfigurations[0].subnet.Id
        $nsgId = $subnet.NetworkSecurityGroup.Id
    }
    #Write-Host "NsgId:" $nsgId

    if ( $nsgId -ne $null) {
        $nsg = $nsgs | ? -Property Id -eq $nsgId

        foreach ($nsgrule in $nsg.SecurityRules) {
            #ConvertTo-Json -InputObject $nsgrule
            $source = $nsgrule.SourceAddressPrefix -join ','
            $port = $nsgrule.DestinationPortRange -join ','
            if ($nsgrule.Direction -eq "Inbound" -and ($source -eq "*" -or $source -eq "Intenet")) {
                #Write-Host "Priority:" $nsgrule.Priority
                $info.NsgName = $nsg.Name
                $info.OpenPort = $port
                $info.Priority = $nsgrule.Priority
                $info.Protocol = $nsgrule.Protocol
                $info.Source = $source

                $report += clone($info)
            }
        }
    }

} 
$report | ft VmName, ResourceGroupName, Region, VmSize, OsType, PublicIPAddress, Status, VirturalNetwork, Subnet, NsgName, OpenPort, Priority, Protocol, Source 
$report | Export-CSV "$home/$reportName"