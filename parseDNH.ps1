
[System.Collections.ArrayList]$DNH = cscript DNH-Validation.vbs
$DNH.Remove('Copyright (C) Microsoft Corporation. All rights reserved.')
$DNH.Remove('Microsoft (R) Windows Script Host Version 5.8')
$DNH.Remove('Reboot Info:')
$DNH.Remove('----------------------------------------')
$DNH.Remove("** WARNING! Server is Clustered!! **")

$option = [System.StringSplitOptions]::RemoveEmptyEntries
$seperator = ":"
$array = $DNH.split($seperator,2,$option)
$table = new-object System.Collections.Hashtable
for ( $i = 0; $i -lt $array.Length; $i += 2 ) {
  $table.Add($array[$i],$array[$i+1]);
}
$table
