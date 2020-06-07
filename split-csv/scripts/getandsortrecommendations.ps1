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

$a | where {$_.subscriptionId -eq "$prodsubid"} | select *, @{Name = 'subscription'; Expression = {$prodsubname}} | export-csv '.\placeholder\azgraphdata.csv'-NoTypeInformation

$a | where {$_.subscriptionId -eq "$nonprodsubid"} | select *, @{Name = 'subscription'; Expression = {$nonprodsubname}} | export-csv '.\placeholder\azgraphdata.csv'-append -NoTypeInformation

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

$Filepath = '.\inputs\update-issues.csv'    ##This is the only file you specify

jointohypercare $Filepath










Set-location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv"

$inputFile = ".\AzureSecurityCenterRecommendations_2020-06-06T21_02_59Z.csv"

$hsevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\highseverityrecommendations.csv"

$msevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\mediumseverityrecommendations.csv"

$lsevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\lowseverityrecommendations.csv"

$file = import-csv $inputFile

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "High"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$hsevfilepath" -NoTypeInformation

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "Medium"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$msevfilepath" -NoTypeInformation

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "Low"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$lsevfilepath" -NoTypeInformation

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\highsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\split-intomfiles.py' --a "$hsevfilepath"  ##

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\mediumsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\split-intomfiles.py' --a "$msevfilepath"  ##

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\lowsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\split-intomfiles.py' --a "$lsevfilepath"  ##

Set-location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv"


#python.exe .\csv-2-lowercase.py --a $L  ##Inline converting to lowercase
#(Get-Content $OuputFile) | Foreach-Object {($_).TOlower()} | Set-Content $OuputFile 