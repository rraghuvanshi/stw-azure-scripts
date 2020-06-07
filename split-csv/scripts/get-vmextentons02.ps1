#Connect-AzAccount

function jointohypercare {
    param (
        $filepath
    )
    
    $prodsubid = "0b731124-849a-49c0-99a8-732f55740893"
$nonprodsubid = "39145e23-d044-41c8-a83d-4bab22cc8f5d"

$prodsubname = "production"
$nonprodsubname = "non-production"

$L = $filepath

$H = '.\inputs\hypercarescope.csv'        ## Update hypercare scope if you need to

$Query1= 'Resources | where type == "microsoft.compute/virtualmachines" | project name, resourceGroup, os = properties.storageProfile.osDisk.osType, environment = tags.environment, businessowner=tags.businessowner, subscriptionId'

$Query2= 'Resources | where type == "microsoft.compute/virtualmachines" | project name, resourceGroup, os = properties.storageProfile.osDisk.osType, osversion = properties.storageProfile.imageReference.sku, environment = tags.environment, subscriptionId, businessowner=tags.businessowner, mtag = tags.maintenancewindow, stag = tags.shutdownwindow, id'

$a = Search-AzGraph -First 3000 -Query $Query1

$a | Where-Object {$_.subscriptionId -eq "$prodsubid"} | Select-Object *, @{Name = 'subscription'; Expression = {$prodsubname}} | export-csv '.\placeholder\azgraphdata.csv'-NoTypeInformation

$a | Where-Object {$_.subscriptionId -eq "$nonprodsubid"} | Select-Object *, @{Name = 'subscription'; Expression = {$nonprodsubname}} | export-csv '.\placeholder\azgraphdata.csv'-append -NoTypeInformation

$R = '.\placeholder\azgraphdata.csv' ##Output from Resource Graph Explorer

#python.exe .\csv-2-lowercase.py --a $L  ##Inline converting to lowercase
#python.exe .\csv-2-lowercase.py --a $R  ##Inline converting to lowercase

(Get-Content $L) | Foreach-Object {($_).Tolower()} | Set-Content $L
(Get-Content $R) | Foreach-Object {($_).Tolower()} | Set-Content $R

csvjoin -c "name,name" --left $L $R > .\placeholder\tmerged.csv

$NL = '.\placeholder\tmerged.csv'

csvjoin -c "name,name" --left $NL $H | csvcut -C "subscriptionid" | csvsort -c "subscription" -r > .\outputs\merged.csv

Remove-Item "$NL" -force
Remove-Item "$R" -force

$outputfile = Import-csv '.\outputs\merged.csv'

return $outputfile
}

$Filepath = '.\inputs\rapid7-issues.csv'    ##This is the only file you specify

$vms = jointohypercare $Filepath

$prodsubid = "0b731124-849a-49c0-99a8-732f55740893"
$nonprodsubid = "39145e23-d044-41c8-a83d-4bab22cc8f5d"

$vmsp = $vms | Where-Object { $_.subscription -eq 'production' } | ConvertTo-Csv -NoTypeInformation
$vmsnp = $vms | Where-Object { $_.subscription -eq 'non-production' } | ConvertTo-Csv -NoTypeInformation

#Provide the name of the csv file to be exported
$reportName = ".\outputs\ALL-VM-EXT.csv"

Select-AzSubscription $prodsubid | Out-Null
#$vmsp = Import-csv ".\placeholder\prodvms.csv"
$vmsp = ConvertFrom-Csv $vmsp
foreach ($item in $vmsp) {
    $info = "" | Select-Object VMName, Name, Publisher, ProvisioningState, TypeHandlerVersion, Id
                
    try {
        $extensions = Get-AzVMExtension -VMName $item.name -ResourceGroupName $item.resourcegroup | Where-Object { $_.Publisher -match "Rapid7.InsightPlatform" } | Select-Object VMName, Name, Publisher, ProvisioningState, TypeHandlerVersion, Id 
        if ($null -eq $extensions) { throw }
    }
               
    Catch {
        $info.VMName = $item.name
        $info.Name = "Rapid7 extenstion not installed"
        $info | export-csv "$reportName" -append
        continue
    }
        
    $extensions | export-csv "$reportName" -append
} 
  
Select-AzSubscription $nonprodsubid | Out-Null
#$vmsnp = Import-csv ".\placeholder\nonprodvms.csv"
$vmsnp = ConvertFrom-Csv $vmsnp
foreach ($item in $vmsnp) {
    $info = "" | Select-Object VMName, Name, Publisher, ProvisioningState, TypeHandlerVersion, Id
                
    try {
        $extensions = Get-AzVMExtension -VMName $item.name -ResourceGroupName $item.resourcegroup | Where-Object { $_.Publisher -match "Rapid7.InsightPlatform" } | Select-Object VMName, Name, Publisher, ProvisioningState, TypeHandlerVersion, Id 
        if ($null -eq $extensions) { throw }
    }
               
    Catch {
        $info.VMName = $item.name
        $info.Name = "Rapid7 extenstion not installed"
        $info | export-csv "$reportName" -append
        continue
    }
        
    $extensions | export-csv "$reportName" -append
} 

#####################################
###Join section

$R = '.\outputs\merged.csv'

$L = $reportName

csvjoin -c "VMName,name" --left $L $R | csvcut -C "Id" | csvsort -c "subscription" -r > .\outputs\finalmerged.csv

if(Test-path ".\outputs\merged.csv") {Remove-item ".\outputs\merged.csv" -Force}

if(Test-path "$reportName") {Remove-item "$reportName" -Force}

