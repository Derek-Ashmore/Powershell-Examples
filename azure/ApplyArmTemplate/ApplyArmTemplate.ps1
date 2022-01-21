#$subscription = "d6ec19c6-066b-4041-ac2a-99a305810922"
#Login-AzAccount
#Set-AzContext -SubscriptionId $subscription

# ./ApplyArmTemplate JMU-AZDEV-VC05-MGMT-NET-RG Dev-Mgmt/template.json
# ./ApplyArmTemplate JMU-AZDEV-VC05-APPS-NET-RG Dev-Apps/template.json

$ResourceGroupName = $Args[0]
$templateFilePath = $Args[1]

#     -TemplateParameterFile  $templateParameterFile `
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $templateFilePath `
    -Mode "Incremental" 

#Write-Host $ErrorMessages