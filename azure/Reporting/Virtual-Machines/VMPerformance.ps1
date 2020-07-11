#Connect to an Azure Account
#   Connect-AzAccount

#Provide the subscription Id where the VMs reside
$subscriptionId = "079fed67-2834-4fc9-bc04-3bdd5fd11228"
$metricStartDate = "2020-06-01"
$metricEndDate = "2020-06-30"
$metricTimeGranularity = "00:05:00"
$metricNames = "Percentage CPU,OS Disk Read Bytes/sec,OS Disk Write Bytes/sec,Data Disk Read Bytes/sec,Data Disk Write Bytes/sec"
$cpuOffset = 0
$osDiskReadOffset = 1
$osDiskWriteOffset = 2
$dataDiskReadOffset = 3
$dataDiskWriteOffset = 4

#Provide the name of the csv file to be exported
$reportName = "virtualMachinePerformance.csv"

function Get-Metric-Average($dataArray) {
    $Total = 0
    $Count = 0
    if ($dataArray.Length -gt 0) {
        foreach ($data in $dataArray) {
            if ($data.Average -gt 0) {
                $Total += $data.Average
                $Count = $Count + 1
            }    
        }    
        if ($Count -gt 0) {
            return $Total / $Count
        } else {
            return "na"
        }
        
    }
    else {
        return "na"
    }
     
}

function Get-Metric-Minimum($dataArray) {
    $Minimum = 9999999
    if ( $dataArray.Length -gt 0 ) {
        foreach ($data in $dataArray) {
            if ( ($data.Average -gt 0) -and ($data.Average -lt $Minimum) ) {
                $Minimum = $data.Average
            }
        }    
        if ( $Minimum -eq 9999999 ) {
            return "na"
        } else {
            return $Minimum
        }
        
    }
    else {
        return "na"
    }
     
}

function Get-Metric-Maximum($dataArray) {
    $Maximum = 0
    $dataToCount = False
    if ($dataArray.Length -gt 0) {
        foreach ($data in $dataArray) {
            $dataToCount = True
            if (($data.Average -gt 0) -and ($data.Average -gt $Maximum) ) {
                $Maximum = $data.Average
            }
        }    
        if ( $dataToCount ) {
            return $Maximum
        } else {
            return "na"
        }
        
    }
    else {
        return "na"
    }
     
}

Select-AzSubscription $subscriptionId
$report = @()
$vms = Get-AzVM -Status
foreach ($vm in $vms) { 
    $info = "" | Select VmName, ResourceGroupName, Region, VmSize, Status, AverageCpuPct, MinCpuPct, MaxCpuPct, AverageOsIIopsRead, MinOsIIopsRead, MaxOsIIopsRead, AverageOsIIopsWrite, MinOsIIopsWrite, MaxOsIIopsWrite, AverageDataIIopsRead, MinDataIIopsRead, MaxDataIIopsRead, AverageDataIIopsWrite, MinDataIIopsWrite, MaxDataIIopsWrite

        $info.VMName = $vm.Name 
        $info.ResourceGroupName = $vm.ResourceGroupName 
        $info.Region = $vm.Location 
        $info.VmSize = $vm.HardwareProfile.VmSize
        $info.Status = $vm.PowerState

        $metrics = Get-AzMetric -ResourceId $vm.Id -StartTime $metricStartDate -EndTime $metricEndDate -DetailedOutput -TimeGrain $metricTimeGranularity -MetricName $metricNames

        $info.MinCpuPct = Get-Metric-Minimum($metrics[$cpuOffset].Data)
        $info.MaxCpuPct = Get-Metric-Maximum($metrics[$cpuOffset].Data)
        $info.AverageCpuPct = Get-Metric-Average($metrics[$cpuOffset].Data)

        $info.MinCpuPct = Get-Metric-Minimum($metrics[$cpuOffset].Data)
        $info.MaxCpuPct = Get-Metric-Maximum($metrics[$cpuOffset].Data)
        $info.AverageCpuPct = Get-Metric-Average($metrics[$cpuOffset].Data)

        $info.AverageOsIIopsRead = Get-Metric-Average($metrics[$osDiskReadOffset].Data)
        $info.MinOsIIopsRead = Get-Metric-Minimum($metrics[$osDiskReadOffset].Data)
        $info.MaxOsIIopsRead = Get-Metric-Maximum($metrics[$osDiskReadOffset].Data)
        
        $info.AverageOsIIopsWrite = Get-Metric-Average($metrics[$osDiskWriteOffset].Data)
        $info.MinOsIIopsWrite = Get-Metric-Minimum($metrics[$osDiskWriteOffset].Data)
        $info.MaxOsIIopsWrite = Get-Metric-Maximum($metrics[$osDiskWriteOffset].Data)
        
        $info.AverageDataIIopsRead = Get-Metric-Average($metrics[$dataDiskReadOffset].Data)
        $info.MinDataIIopsRead = Get-Metric-Minimum($metrics[$dataDiskReadOffset].Data)
        $info.MaxDataIIopsRead = Get-Metric-Maximum($metrics[$dataDiskReadOffset].Data)
        
        $info.AverageDataIIopsWrite = Get-Metric-Average($metrics[$dataDiskWriteOffset].Data)
        $info.MinDataIIopsWrite = Get-Metric-Minimum($metrics[$dataDiskWriteOffset].Data)
        $info.MaxDataIIopsWrite = Get-Metric-Maximum($metrics[$dataDiskWriteOffset].Data)
        
        $report+=$info 
    } 
$report | ft VmName, ResourceGroupName, Region, VmSize, Status, AverageCpuPct, MinCpuPct, MaxCpuPct, AverageOsIIopsRead, MinOsIIopsRead, MaxOsIIopsRead, AverageOsIIopsWrite, MinOsIIopsWrite, MaxOsIIopsWrite, AverageDataIIopsRead, MinDataIIopsRead, MaxDataIIopsRead, AverageDataIIopsWrite, MinDataIIopsWrite, MaxDataIIopsWrite 
$report | Export-CSV "$home/$reportName"