Function Get-UnallocatedSpace{
[cmdletbinding()]
    param()

Begin{}
Process{
$disks = gwmi win32_diskdrive 
$partitions = gwmi win32_diskpartition
$unpartitioned = 0
$allocatedspace = 0
$PartitionCount = 0
$obj = $null


foreach($disk in $disks) {

    foreach($partition in $partitions) {

        if($partition.DiskIndex -eq $disk.index) {

            $partitionCount++

            $allocatedspace += $partition.size

        }

    }
    $UnallocatedSpace = ($disk.size - $AllocatedSpace)/1GB

    Create-DiskObject -index $disk.index -size $disk.size -PartitionCount $PartitionCount -UnallocatedSpace $UnallocatedSpace

   $AllocatedSpace=0

   $PartitionCount=0
    #$TargetDisk = $DiskObj | where {$_.UnallocatedSpace -gt 1}
#$TargetDisk
    
}
}
End{}
}

Function Resize-Disk{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$DiskIndex,
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$PartitionCount)
    Begin{}
    Process{
    "select disk $DiskIndex","select partition $PartitionCount","extend","exit" | diskpart | Out-Null
    }
    End{}
}

Function Create-DiskObject{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Index,
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Size,
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$PartitionCount,
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$UnallocatedSpace
    )
 Begin{}
 Process{
$diskobj = New-Object -TypeName PSObject

    $diskobj | Add-Member -MemberType NoteProperty -Name DiskIndex -Value $disk.index

    $diskobj | Add-Member -MemberType NoteProperty -Name TotalSpace -Value $disk.size 

    $diskobj | Add-Member -MemberType NoteProperty -Name PartitionCount -Value $PartitionCount

    $diskobj | Add-Member -MemberType NoteProperty -Name UnallocatedSpace -Value $UnallocatedSpace

Write-Output $diskobj
}
End{}
}