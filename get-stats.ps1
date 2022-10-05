Function Get-Stats{
[cmdletbinding()]
param(
[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$server)
    Begin{}
    Process{
    #Start-Sleep -Seconds 15
    (Get-Counter -ComputerName $server -Counter "\Processor(*)\% Processor Time","\LogicalDisk(*)\% Free Space","\LogicalDisk(*)\Free Megabytes","\Memory\% Committed Bytes In Use","\Memory\Available MBytes").countersamples

}
End{}
}

$servers=Get-Content servers.txt
$vm = Get-VM -Name $servers -server $cd

$servers=Get-Content servers.txt
$vm = Get-VM -Name $servers -server $od

$VM | ForEach-Object {("Name: " + $_.Name + "   CPU: "+ $_.NumCPU+ "   Mem: "+ $_.MemoryGB)} | clip.exe
$VM | ForEach-Object {("Name: " + $_.Name), "CapacityGB      FreeSpaceGB     Path",$_.guest.disks} | clip.exe


(Get-Counter -Counter "\Processor(*)\% Processor Time","\system\Processor Queue Length","\Memory\% Committed Bytes In Use","\MSMQ Service\MSMQ Incoming Messages","\MSMQ Service\MSMQ Outgoing Messages","\MSMQ Queue(*)\Messages in Queue","\MSMQ Service\Total messages in all queues","\MSMQ Session(*)\Outgoing Messages/sec","\MSMQ Session(*)\Incoming Messages/sec" -MaxSamples 10).countersamples