
$SourcePath = ""
#$FileName = ""
$DestinationPath = @"



"@
#New-PSDrive -Name source -PSProvider FileSystem -Root $SourcePath | Out-Null
#New-PSDrive -Name destination -PSProvider FileSystem -Root $DestinationPath | Out-Null

$DestinationArray = New-Object System.Collections.ArrayList
$DestinationArray = $DestinationPath -split "`n"
$DestinationArray | ForEach-Object { Copy-Item -Path $SourcePath -Destination $_}
