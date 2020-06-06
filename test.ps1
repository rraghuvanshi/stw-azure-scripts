
$OuputFile = ".\inputs\monitoring-agent-issues.csv"
#python.exe .\csv-2-lowercase.py --a $OuputFile  ##Inline converting to lowercase
(Get-Content $OuputFile) | Foreach-Object {($_).TOlower()} | Set-Content $OuputFile 