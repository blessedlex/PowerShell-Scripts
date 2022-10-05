Function Get-VMStats{
[cmdletbinding()]
param(
[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$vm,
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$server
        
    )
Connect-ViServer $server
Connect-ViServer $server
$VM = Get-VM -Name $vm -server $server
$VM | ForEach-Object {("Name: " + $_.Name + "   CPU: "+ $_.NumCPU+ "   Mem: "+ $_.MemoryGB + $_.guest.disks)}

}

Connect-ViServer xxxxxx.com
$vm = Get-VM -name xxxxxxx
$vm.guest.disks
$vm = Get-VM -name xxxxxx| ForEach-Object {("Name: " + $_.Name + "   CPU: "+ $_.NumCPU+ "   Mem: "+ $_.MemoryGB + $_.guest.disks)}