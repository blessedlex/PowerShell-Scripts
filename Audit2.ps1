set-location C:\Users\xxxxxxx\Desktop
$wcsv=Import-CSV .\folders_groups.csv
$wcsv| foreach{
$Path=$_.Path
$Group=$_.IdentityReference

If ($_.IdentityReference -match "STWGAVEHREN|STAREMBS|STARAFFIX"){
Get-ADUSER -identity ($_.identityreference.split('\')[1]) -server ($_.identityreference.split('\')[0]) -Property SamAccountName, DisplayName, DistinguishedName, Enabled `
|Select @{n='Path';e={$Path}}, @{n='Group';e={$Group}}, SamAccountNAme, DisplayName, Enabled, @{n='Quarantine';e={($_.DistinguishedName -match 'Quarantine')}}| Export-CSV 4cindy.csv -NoTypeInformation -Append
}
Else{
get-adgroupmember -identity ($_.identityreference.split('\')[1]) -server ($_.identityreference.split('\')[0]) | Get-ADUSER -Property SamAccountName, DisplayName, DistinguishedName, Enabled `
|Select @{n='Path';e={$Path}}, @{n='Group';e={$Group}}, SamAccountNAme, DisplayName, Enabled, @{n='Quarantine';e={($_.DistinguishedName -match 'Quarantine')}}| Export-CSV 4cindy.csv -NoTypeInformation -Append
}
}