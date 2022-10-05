$servers= @"
x
x
x
x
x
x
x
"@ -split "`n" | ForEach-Object{$_.trim()}

 $Servers | ForEach-Object {
 $_
 ([system.net.dns]::GetHostAddresses("$_")).ipaddresstostring
 }

