#Connect-AzAccount

function jointohypercare {
    param (
        $filepath
    )
    
#$prodsubid = "0b731124-849a-49c0-99a8-732f55740893"
#$nonprodsubid = "39145e23-d044-41c8-a83d-4bab22cc8f5d"

#$prodsubname = "production"
#$nonprodsubname = "non-production"

$L = $filepath

$H = 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\inputs\hypercarescope.csv'        ## Update hypercare scope if you need to

$Query1= 'Resources | where type == "microsoft.compute/virtualmachines" | project name, os = properties.storageProfile.osDisk.osType, environment = tags.environment, businessowner=tags.businessowner'

#$Query2= 'Resources | where type == "microsoft.compute/virtualmachines" | project name, resourceGroup, os = properties.storageProfile.osDisk.osType, osversion = properties.storageProfile.imageReference.sku, environment = tags.environment, subscriptionId, businessowner=tags.businessowner, mtag = tags.maintenancewindow, stag = tags.shutdownwindow, id'

Search-AzGraph -First 3000 -Query $Query1 | export-csv 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\azgraphdata.csv'-NoTypeInformation

#$a | where {$_.subscriptionId -eq "$prodsubid"} | select *, @{Name = 'subscription'; Expression = {$prodsubname}} | export-csv 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\azgraphdata.csv'-NoTypeInformation

#$a | where {$_.subscriptionId -eq "$nonprodsubid"} | select *, @{Name = 'subscription'; Expression = {$nonprodsubname}} | export-csv 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\azgraphdata.csv' -append -NoTypeInformation

$R = 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\azgraphdata.csv' ##Output from Resource Graph Explorer

#python.exe "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\scripts\csv-2-lowercase.py" -a $L  ##Inline converting to lowercase
#python.exe "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\scripts\csv-2-lowercase.py" --a $R  ##Inline converting to lowercase

#(Get-Content $L) | Foreach-Object {($_).Tolower()} | Set-Content $L
(Get-Content $R) | Foreach-Object {($_).Tolower()} | Set-Content $R


csvjoin -c "resourcename,name" --left $L $R > "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\tmerged.csv"

$NL = 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\tmerged.csv'

csvjoin -c "resourcename,name" --left $NL $H | csvsort -c "subscriptionname" -r > "$filepath"

Remove-Item "$NL" -force
Remove-Item "$R" -force

#$outputfile = Import-csv 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\merged.csv'

#return $outputfile
}

Set-location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\inputs"

$inputFile = Get-ChildItem -Path "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\inputs" -Filter '*.csv' | Where-Object {$_.Name -like "AzureSecurityCenterRecommendations*"} | Select-Object FullName

$inputFile = $inputFile.FullName

#$inputFile = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\inputs\AzureSecurityCenterRecommendations_2020-06-06T21_02_59Z.csv"

$hsevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\highseverityrecommendations.csv"

$msevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\mediumseverityrecommendations.csv"

$lsevfilepath = "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\placeholder\lowseverityrecommendations.csv"

$file = import-csv $inputFile

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "High"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$hsevfilepath" -NoTypeInformation

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "Medium"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$msevfilepath" -NoTypeInformation

$file | Where-Object {$_.state -match 'Unhealthy' -and $_.resourceType -match 'virtualMachines' -and $_.severity -match "Low"} | Select-Object resourceName, resourceType, resourceGroup, subscriptionName, recommendationDisplayName, state, severity | export-csv "$lsevfilepath" -NoTypeInformation

###converting everything to lower

(Get-Content $hsevfilepath) | Foreach-Object {($_).Tolower()} | Set-Content $hsevfilepath
(Get-Content $msevfilepath) | Foreach-Object {($_).Tolower()} | Set-Content $msevfilepath
(Get-Content $lsevfilepath) | Foreach-Object {($_).Tolower()} | Set-Content $lsevfilepath

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\highsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\scripts\split-intomfiles.py' --a "$hsevfilepath"  ##

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\mediumsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\scripts\split-intomfiles.py' --a "$msevfilepath"  ##

Set-Location "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\lowsev"

python.exe 'C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\scripts\split-intomfiles.py' --a "$lsevfilepath"  ##


##########Doing the merge with hypercare

$hscsvs = Get-ChildItem -Path "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\highsev" -Filter '*.csv' | Select-Object FullName

foreach($csv in $hscsvs){ 
    $pathofcsv = $csv.FullName
    jointohypercare $pathofcsv}


$mscsvs = Get-ChildItem -Path "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\mediumsev" -Filter '*.csv' | Select-Object FullName

foreach($csv in $mscsvs){ 
    $pathofcsv = $csv.FullName
    jointohypercare $pathofcsv}

$lscsvs = Get-ChildItem -Path "C:\azureadmin\stw-azure-scripts\stw-azure-scripts\split-csv\outputs\lowsev" -Filter '*.csv' | Select-Object FullName

foreach($csv in $lscsvs){ 
    $pathofcsv = $csv.FullName
    jointohypercare $pathofcsv}

