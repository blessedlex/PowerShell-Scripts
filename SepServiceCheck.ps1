#This script checks for the Symantec Endpoint Protection Service 
If (Get-Service | Where-Object {$_.Name -eq 'SepMasterService'}){
$SepServiceExists = $True
$SepServiceStatus =  (get-service -name SepMasterService).status
$ErrorActionPreference="Stop"
Try{
[System.Diagnostics.EventLog]::SourceExists("FDC Script") -eq $True
}
Catch [System.Management.Automation.MethodInvocationException]{
New-EventLog -LogName Application -Source "FDC Script"
}
Finally{
Write-EventLog -LogName Application -Source "FDC Script" -EntryType Warning -EventId 50 -Message "Symantec Endpoint Protection Service Found and current status is $SepServiceStatus"
$ErrorActionPreference="Continue"
}
}
Else{
$SepServiceExists = $False
$SepServiceStatus = "N/A"
}


