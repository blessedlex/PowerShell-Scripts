Param([string]$Mode='Pre')

# TODO Add final check

Function Get-Stats{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Mode
    )
Begin{
# Get last reboot time and calculate up time
$OS = Get-WmiObject Win32_OperatingSystem
$LastBootUpTime = $OS.ConvertToDateTime($os.LastBootUpTime)
$LocalDateTime = $OS.ConvertToDateTime($os.LocalDateTime)
$up = $LocalDateTime - $LastBootUpTime
$uptime = "$($up.Days) days, $($up.Hours)h, $($up.Minutes)mins"
$ScriptRunMode=$Mode
<#remove post override
If (($args.count -eq 0) -and ($up.TotalMinutes -lt 30)){
$Mode = 'Post'
$ScriptRunMode='Post Override'
}
#>
$NotStartedServices='N/A'
IF(get-service ClusSvc -erroraction SilentlyContinue){$IsClustered=$True}Else{$IsClustered=$False}
$IsRPCStarted=$False
$IsRDPStarted=$False
$IsVirtual=$False
$VMToolsVer='N/A'
$VMToolsUpStatus='N/A'
$CheckPath="C:\TEMP\PoshDNH"
If($Mode -eq 'Pre'){Remove-OldFiles}
If(($Mode -ne 'Check') -and ($Mode -ne 'Final') -and (-Not(Test-Path $CheckPath))){New-Item -ItemType Directory -Path $CheckPath}
$PowerPlan=(Get-WMIObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "isActive='true'").elementname
If ($PowerPlan -ne 'High performance'){
    $DesiredPowerPlan=Get-WMIObject -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High performance'"
    Invoke-WMIMethod -InputObject $DesiredPowerPlan -MethodName Activate
    $PowerPlan=(Get-WMIObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "isActive='true'").elementname
    If ($PowerPlan -eq 'High performance'){$PowerPlanCompliance = $True}
    }
Else {$PowerPlanCompliance = $True}
$LastPatchDate=(Get-WMIObject win32_quickfixengineering |sort installedon -desc |Select -First 1).InstalledOn
$LastPatchDate='{0:dd/MM/yyyy}' -f $LastPatchDate

<#
Delay time is in seconds
For normal use, we will use 240, for 4 minutes
For instant use, use option Now with Pre, to give 15 second response
#>
$DelayTime = 240
If($Mode -eq 'Post'){Start-Sleep $DelayTime}
#Sample time in seconds used for Performance Counters
$SampleTime=10
$ScriptRunTime=Get-Date
#Service Check
$ServiceObject=Get-ServiceStatus
If($IsClustered -and ($Mode -eq "Check" -or "Pre")){Write-Host "** WARNING! Server is Clustered!! **"}
If($IsClustered){
Import-Module FailoverClusters
$ClusterInfo=Get-ClusterGroup}
<#
 Limit for Drive Space
 Value in Bytes
 Anything LESS than this value results in a FAIL
 3Gb = 3221225472
 2Gb = 2147483648
 1Gb = 1073741824
 .5Gb = 536870912
 #>
$DiskBytesLimit = 1
# Define the Clear Page File on Statrup Registry key
$CacheKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$CacheEntry= "ClearPageFileAtShutdown"



# Define the Registry keys for possible reboots
$AURebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
$CBRebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
$PendFileRenameKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\"
$PendFileRenameEntry="PendingFileRenameOperations"
$EXEVolatileKey = "HKLM:\SOFTWARE\Microsoft\Updates\UpdateExeVolatile"
}
Process{
# Try to retrieve cache entry value
$ErrorActionPreference="Stop"
Try {$CacheEntryValue=(Get-ItemProperty -name $CacheEntry -Path $CacheKey).ClearPageFileAtShutdown}
Catch [System.Management.Automation.PSArgumentException]{$CacheEntryValue=$Null}
Finally{$ErrorActionPreference="Continue"}

# Is Virtual Check
If(Test-Path "C:\Program Files\VMware\Vmware Tools\"){
$IsVirtual=$True
$VmPath="C:\Program Files\VMware\Vmware Tools\"
}
ElseIf(Test-Path "C:\Program Files (x86)\VMware\Vmware Tools\"){
$IsVirtual=$True
$VmPath="C:\Program Files (x86)\VMware\Vmware Tools\"
}
#If IsVirtual is true get version
If($IsVirtual){
Push-Location $VmPath
Try{$VMToolsVer= .\vmwaretoolboxcmd -v}Catch{$VMToolsVer='N/A'}
Try{$VMToolsUpStatus=.\vmwaretoolboxcmd upgrade status}Catch{$VMToolsUpStatus='N/A'}
Pop-Location
}

# Pending Reboot Check
# Try to retrieve pending file rename operations
Get-ItemProperty -Path $PendFileRenameKey -name $PendFileRenameEntry -ErrorAction SilentlyContinue |Foreach{If($_.PendingFileRenameOperations){$PendFileEntryValue = $_.PendingFileRenameOperations}Else{$PendFileEntryValue = $Null}}

$RebootObject = New-Object -ComObject "Microsoft.Update.SystemInfo"
If ($RebootObject.RebootRequired -eq $True){
    $RebootCheck = 'Fail'
}
ElseIf ($RebootObject.RebootRequired -eq $False){
    $RebootCheck = 'Pass'
}
If (Test-Path $AURebootRequiredKey){
    $RebootCheck = 'Fail'
    $AURebootRequiredStr='Key Not Found'
}
Else{$AURebootRequiredStr='Key Auto Update Reboot Required'}
<#
If (Test-Path $CBRebootRequiredKey){
    $RebootCheck = 'Fail'
    $CBRebootRequiredStr='Key Not Found'
}
Else{$CBRebootRequiredStr='Key Component Based Servicing Reboot Required'}
#>
If ((Test-Path $PendFileRenameKey) -and ($PendFileEntryValue -ne $Null)){
    $RebootCheck = 'Fail'
    $PendFileRenameStr='Key Not Found'
}
Else{$PendFileRenameStr='Key Pending Files Renames'}
If (Test-Path $EXEVolatileKey){
    $RebootCheck = 'Fail'
    $EXEVolatileStr='Key Not Found'
}
Else{$EXEVolatileStr='Key EXE Volatile'}
If ($RebootCheck-eq 'Fail'){$RebootText='Reboot Required'}
ElseIf ($RebootCheck -eq 'Pass'){$RebootText='Reboot NOT Required'}

# Cache File Clear at Shutdown Status Check
If (-Not(Test-Path $CacheKey)){
$CacheCheck='Fail'
$CacheReason='Cache Key Fail Reason: FAIL Cache file flag not found'
}
ElseIf((Test-Path $CacheKey) -and ($CacheEntryValue=0)){
$CacheCheck='Pass'
$CacheReason='Cache Key Pass Reason: PASS Cache file WILL NOT not be cleared.'
}
ElseIf((Test-Path $CacheKey) -and ($CacheEntryValue=1)){
    If($IsVirtual){
    $CacheCheck='Pass'
    $CacheReason='Cache Key Pass Reason: PASS Cache file WILL be cleared. Server is Virtual'
    }
    Else{
    $CacheCheck='Fail'
    $CacheReason='Cache Key Fail Reason: FAIL Cache file WILL be cleared. Server is Physical'
    }
}
# Get last reboot time and calculate up time
$LastBootUpTime = $OS.ConvertToDateTime($os.LastBootUpTime)
$LocalDateTime = $OS.ConvertToDateTime($os.LocalDateTime)
$up = $LocalDateTime - $LastBootUpTime
$uptime = "$($up.Days) days, $($up.Hours)h, $($up.Minutes)mins"


# PowerShell Version
$PoshVer=(host).Version.Major
# MS Installer Version
$MSIVer=(Get-Childitem C:\windows\system32\msi.dll | Select-Object -ExpandProperty VersionInfo).fileversion
# OS Version
$OSCaption=$OS.Caption
$OSVer=$OS.Version
$ServicePack=($OS.ServicePackMajorVersion).ToString() + "." + ($OS.ServicePackMinorVersion).ToString()
$InstallDate=$OS.ConvertToDateTime($OS.InstallDate)

# Display based on Mode
If(($Mode -ne 'Check') -and ($Mode -ne 'Pre')){$Logs = Get-LogEntries}Else{$Logs = Get-LogEntries $LastBootUpTime}
$LogsDisplayed=@()
If ($Mode -ne 'Final'){
$LogsDisplayed=$LogsDisplayed+($Logs.SysInfo1074|Select-Object -First 1)+($Logs.AppInfoCogbot|Select-Object -First 1)
}
If(($Mode -ne 'Check') -and ($Mode -ne 'Pre')){$LogsDisplayed=$LogsDisplayed+$Logs.SysErrors+$Logs.AppErrors}

}

End{
<#
$AUStatus
$AUStartType
$IsRPCStarted
$IsRDPStarted
$uptime
$up
#>
$StatsProperties=@{'Script Run Mode'=$ScriptRunMode;
                    'Script Run Time'=$ScriptRunTime;
                    'Last Patch Date'=$LastPatchDate;
                    'OS Caption'=$OSCaption;
                    'OS Version'=$OSVer;
                    'Service Pack'=$ServicePack;
                    'Install Date'=$InstallDate;
                    'Powershell Version'=$PoshVer;
                    'MSI Version'=$MSIVer;
                    'Power Plan'=$PowerPlan;
                    'Pending Reboot Check'=$RebootCheck;
                    'Reboot Required?'=$RebootText;
                    'UpTime'=$up;
                    'Windows Update Check'=$ServiceObject.WUCheck;
                    'Windows Update Text'=$ServiceObject.WUReason;
                    'Server Is Clustered'=$ServiceObject.IsClustered;
                    'RDP Check'=$ServiceObject.RDPCheck;
                    'Server Is Virtual'=$IsVirtual;
                    'VM Tools Version'=$VMToolsVer;
                    'VMTools Update Status'=$VMToolsUpStatus;
                    'Cache File Check'=$CacheCheck;
                    'Cache File Reason'=$CacheReason;
                    'Auto Start Services Not Running'=$ServiceObject.AutoStartSerivcesNotRunning;
                    'Service Check'=$ServiceObject.ServiceCheck;
                    'Service Compare Results'=$ServiceObject.CompareServices;
                    'Last Reboot'=$Logs.lastreboottime;
                    'Last Reboot Message'=$Logs.lastrebootmessage
                    }

$StatsObject=New-Object -TypeName PSObject -Property $StatsProperties| Select 'Script Run Mode','Script Run Time','Last Patch Date','OS Caption','OS Version','Service Pack','Install Date','Powershell Version','MSI Version','Power Plan','Pending Reboot Check','Reboot Required?','UpTime','Windows Update Check','Windows Update Text','Server Is Clustered','RDP Check','Server Is Virtual','VM Tools Version','VMTools Update Status','Cache File Check','Cache File Reason','Last Reboot','Last Reboot Message','Auto Start Services Not Running','Service Check','Service Compare Results'
If($up.Days -ge 180){Write-Host `### Server not rebooted in $up.Days days `###}
Write-Output $StatsObject
Get-Metrics -SampleTime $SampleTime
Get-Misc
Write-Host "Cluster Stats"
$ClusterInfo
If($Mode -ne 'Check'){$LogsDisplayed}
}
}

Function Get-Misc{
# Get Certs expiring in 75 days
$Cert = Get-ChildItem -Path cert: -Recurse | where { $_.notafter -le (get-date).AddDays(30) -AND $_.notafter -gt (get-date)} | select thumbprint,  @{n="Subject";e={$_.subject| foreach-Object{(($_ -replace "\w{1,3}=","").split(",")[0] -replace "}","")}}}, @{n="SignatureAlgorithm";e={$_.SignatureAlgorithm.FriendlyName}}, notafter
# Get SEP Ver
$SepPath="hklm:SOFTWARE\Symantec\Symantec Endpoint Protection\currentversion\"
If(Test-Path $SepPath){
$SEPver=(Get-ItemProperty $SepPath).productversion
$SEPhotfix=(Get-ItemProperty $SepPath).hotfixrevision}
Else{$SEPver='N/A'
$SEPhotfix='N/A'
}

$MiscProperties=@{  'CertsExpiring'=$Cert;
                    'SymantecVersion'=$SEPver;
                    'SymantecHotFix'=$SEPhotfix}
$MiscObject=New-Object -TypeName PSObject -Property $MiscProperties | Select CertsExpiring, SymantecVersion, SymantecHotFix

Write-Output $MiscObject

}

Function Get-LogEntries{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$After=((Get-Date).AddDays(-1))
    )

$ErrorActionPreference="SilentlyContinue"
# Get various log events
# Get all reboot events
$System = Get-WinEvent -MaxEvents 10000 -FilterHashtable @{LogName='System'; StartTime=$After}| Select TimeCreated, ProviderName, ID, LevelDisplayName, Message
$Startup= $System | Where{$_.ID -eq '6009'}
# Get all System Errors
$SysErrors=$System| Where{$_.LevelDisplayName -eq 'Error'}|Select -First 1
# Get all System Warnings
$SysWarnings=$System| Where{$_.LevelDisplayName -eq 'Warning'}|Select -First 1
# Get System Info ID 1074
$SysInfo1074=get-winevent @{LogName='System'; ID='1074'} -maxevents 1
# Get all Application Errors
$Application=Get-WinEvent -MaxEvents 100 -FilterHashtable @{LogName='Application'; StartTime=$After}| Select TimeCreated, ProviderName, ID, LevelDisplayName, Message
$AppErrors=$Application| Where{$_.LevelDisplayName -eq 'Error'}|Select -First 1
# Get all Application Warnings
$AppWarnings=$Application| Where{$_.LevelDisplayName -eq 'Warning'}|Select -First 1
# Get Application Info ID 1 from Cogbot
$AppInfoCogbot=$Application | Where{($_.ID -eq '1') -and ($_.ProviderName -eq 'Cogbot')}|Select -First 1
$LastReboot = $SysInfo1074
$LastRebootTime=$LastReboot.TimeCreated
$LastRebootMessage=$LastReboot.Message
$LogProperties=@{'StartUp'=$StartUp;
                    'SysErrors'=$SysErrors;
                    'SysWarnings'=$SysWarnings;
                    'SysInfo1074'=$SysInfo1074;
                    'AppErrors'=$AppErrors;
                    'AppWarnings'=$AppWarnings;
                    'LastRebootTime'=$LastRebootTime;
                    'LastRebootMessage'=$LastRebootMessage;
                    'AppInfoCogbot'=$AppInfoCogbot}
$LogObject=New-Object -TypeName PSObject -Property $LogProperties | Select SysErrors, SysWarnings, SysInfo1074, AppErrors, AppWarnings, LastRebootTime, LastRebootMessage, AppInfoCogbot
$ErrorActionPreference="Continue"
Write-Output $LogObject
}



Function Get-Metrics{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$SampleTime=10
    )
    #Get various performance metrics
$DiskPerfDisabled =(Get-ItemProperty -path HKLM:\system\CurrentControlSet\Services\Perfdisk\Performance -name "Disable Performance Counters" -ErrorAction SilentlyContinue)."Disable Performance Counters" 
$Metrics=(Get-Counter -Counter "\LogicalDisk(C:)\Free Megabytes","\Processor(_total)\% Processor Time","\Memory\% Committed Bytes In Use","\Memory\Available MBytes","\Paging File(_total)\% Usage" -MaxSamples $SampleTime)|Select -ExpandProperty CounterSamples
# Drive Metrics
# C: Drive Space Check
If ($DiskPerfDisabled){$DiskFreeGB=(Get-WMIObject Win32_Logicaldisk -filter "deviceid='C:'").freespace/1gb}
Else{
$DiskFreeGB=[math]::Round(((($Metrics | Where {$_.Path -eq "\\$env:COMPUTERNAME\logicaldisk(c:)\free megabytes"})|foreach{$_.CookedValue}|Measure-Object -Average).Average)/1024)}
If ($DiskFreeGB -ge $DiskBytesLimit){$DiskSpaceCheck='Pass'}Else {$DiskSPaceCheck='Fail'}
# CPU Metrics
$CpuPc=[math]::Round((($Metrics | Where {$_.Path -eq "\\$env:COMPUTERNAME\processor(_total)\% processor time"})|foreach{$_.CookedValue}| Measure-Object -Average).Average)
If ($CpuPc -lt 90){$CPUCheck='Pass'}Else{$CPUCheck='Fail'}
# Mem Metrics
$MemPc=[math]::Round((($Metrics | Where {$_.Path -eq "\\$env:COMPUTERNAME\memory\% committed bytes in use"})|foreach{$_.CookedValue}|Measure-Object -Average).Average)
If ($Mempc -lt 90){$MemPcCheck='Pass'}Else{$MemPcCheck='Fail'}
$MemAvail=[math]::Round((($Metrics | Where {$_.Path -eq "\\$env:COMPUTERNAME\memory\available mbytes"})|foreach{$_.CookedValue}|Measure-Object -Average).Average)
If ($MemAvail -gt 200){$MemAvailCheck='Pass'}Else{$MemAvailCheck='Fail'}
# Page File Usage
$PageFileUsage=[math]::Round((($Metrics | Where {$_.Path -eq "\\$env:COMPUTERNAME\Paging File(_total)\% Usage"})|foreach{$_.CookedValue}|Measure-Object -Average).Average)
$MetricProperties=@{'SystemDiskFreeGB'=$DiskFreeGB;
                    'DiskSpaceCheck'=$DiskSpaceCheck;
                    'PercentCPU'=$CpuPc;
                    'CPUCheck'=$CPUCheck;
                    'PercentMemory'=$MemPc;
                    'MemoryAvailable'=$MemAvail;
                    'MemoryAvailableCheck'=$MemAvailCheck;
                    'PageFileUsage'=$PageFileUsage}
$MetricObject=New-Object -TypeName PSObject -Property $MetricProperties | Select SystemDiskFreeGB, DiskSpaceCheck, PercentCPU, CPUCheck, PercentMemory, MemoryAvailable, MemoryAvailableCheck, PageFileUsage
Write-Output $MetricObject
}

Function Remove-OldFiles{
$CheckPath="C:\TEMP\PoshDNH"
If(Test-Path $CheckPath\Services.csv){Remove-Item $CheckPath\Services.csv}
Start-Sleep 1
If(Test-Path $CheckPath){Remove-Item $CheckPath -Force -Recurse}
}

Function Get-ServiceStatus{
    $Filter="AeLookupSvc|BITS|CDPSvc|CDPUserSvc_*|clr_optimization.*|DirectAudit Agent|fdphost|GISvc|gupdate|iphlpsvc|MapsBroker|MMCSS|NlaSvc|nsrpsd|OneSyncSvc_*|RemoteRegistry|ShellHWDetection|sppsvc|tapisrv|tiledatamodelsvc|tracksvc|TrustedInstaller|WdiSystemHost|WebClient|WMPNetworkSvc|wmiApSrv|wuauserv"
# Service Check and set service status variables
$Services = Get-WmiObject -Class Win32_Service -Property Name, DisplayName, State, StartMode| Select Name, DisplayName, State, StartMode
If ($Services | Where-Object {$_.Name -eq 'RpcSs' -and $_.State -eq 'Running'}){
$IsRPCStarted=$True
$RPCStatus="Running"
}
If ($Services | Where-Object {$_.Name -eq 'TermService'-and $_.State -eq 'Running'}){
$RDPStatus="Running"
$IsRDPStarted=$True
}
$AUStatus=($Services | Where-Object {$_.Name -eq 'wuauserv'}).State
$AUStartType=($Services | Where-Object {$_.Name -eq 'wuauserv'}).StartMode
$AutoStartSerivcesNotRunning = $Services | Where-Object{$_.Name -NotMatch $Filter} | ForEach-Object{If(($_.StartMode -eq 'Auto' -and $_.State -ne 'Running')){$_.DisplayName}}
#Start NotStarted Services
IF($AutoStartSerivcesNotRunning){
$AutoStartSerivcesNotRunning |ForEach-Object {
Start-Service $_ -ErrorAction SilentlyContinue
}
}
#2nd Auto Start Check After attempt to start
$AutoStartSerivcesNotRunning = $Services | Where-Object{$_.Name -NotMatch $Filter} | ForEach-Object{If(($_.StartMode -eq 'Auto' -and $_.State -ne 'Running')){$_.DisplayName}}
If ($AutoStartSerivcesNotRunning -eq $Null){$AutoStartSerivcesNotRunning = "Pass"}
# Write or compare services based on mode
If($Mode -eq 'Pre'){$Services | Select Name, DisplayName, State, StartMode | Export-CSV $CheckPath\Services.csv
$ServiceCheck='N/A'
}
If(($Mode -ne 'Check') -and ($Mode -ne 'Pre')){
# TODO Insert try
# Import CSV used for compare
$Services = Get-WmiObject -Class Win32_Service -Property Name, DisplayName, State, StartMode| Select Name, DisplayName, State, StartMode
$PreServices = (Import-CSV $CheckPath\Services.csv) | Where-Object{$_.Name -NotMatch $Filter}
$PostServices = $Services | Where-Object{$_.Name -NotMatch $Filter}
$CompareState = Compare-Object -ReferenceObject $PreServices -DifferenceObject $PostServices -Property Name, State
#$CompareStartMode = Compare-Object -ReferenceObject $PreServices -DifferenceObject $PostServices -Property Name, StartMode
If ($CompareState){
$CompareState=$CompareState| Group-Object -Property Name |% {New-Object -TypeName PSObject -Property @{ Service=$_.name;  OldValue=($_.group[1].State); NewValue=($_.group[0].State) } } 
#$CompareStartMode=$CompareStartMode| Group-Object -Property Name |% {New-Object -TypeName PSObject -Property @{ Service=$_.name; OldValue=($_.group[1].StartMode); NewValue=($_.group[0].StartMode) } } 
$CompareServices=($CompareState|Where{$_.NewValue -eq 'Stopped'}|Select Service).Service
IF($CompareServices){$ServiceCheck='Fail, Services Not Started '+$CompareServices}
Else{$ServiceCheck='Pass';$CompareServices="All Services Started"}
}
}
Else{$CompareServices='N/A'}

# Windows Update Service Check
If ($AUStatus -eq 'Running' -and ($AUStartType -eq 'Manual' -or $AUStartType -eq 'Auto')){
$WUCheck='Pass'
$WUReason='N/A'
}
# RDP Availability Check


$RDPReason=$Null
If($IsRPCStarted -and $IsRDPStarted){$RDPCheck='Pass'}Else{$RDPCheck='Fail'}
    If (-Not($IsRPCStarted)){$RPCStatus='RPC Status: FAIL Remote Procedure Call (RPC) Service not started.'}
    If(-Not($IsRDPStarted)){$RDPStatus='RDP Status: FAIL Terminal Services Service not started.'}
    If($RDPCheck -eq 'Fail'){$RDPReason=$RPCStatus + $RDPStatus}

Else {
$WUCheck='Fail'
$WUReason="Windows Update Service is $AUStatus and is set to $AUStartType."
}
$ServiceProperties=@{'IsClustered'=$IsClustered;
                    'ServiceCheck'=$ServiceCheck;
                    'CompareServices'=$CompareServices;
                    'WUCheck'=$WUCheck;
					'WUReason'=$WUReason;
					'RDPCheck'=$RDPCheck;
                    'RDPStatus'=$RDPStatus;
                    'RDPReason'=$RDPReason;
					'AutoStartSerivcesNotRunning'=$AutoStartSerivcesNotRunning
					}
$ServiceObject=New-Object -TypeName PSObject -Property $ServiceProperties | Select IsClustered, ServiceCheck, CompareServices, WUCheck, WUReason, RDPCheck, RDPStatus, RDPReason, AutoStartSerivcesNotRunning
Write-Output $ServiceObject


}

Get-Stats $Mode
exit 0