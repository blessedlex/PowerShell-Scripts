Function Test-Credential{
$Credential = ($Credential = get-credential -credential $env:userdnsdomain\$env:username)
$Domain=$Credential.UserName.Split("{\}")[0]
$User=$Credential.UserName.Split("{\}")[1]
$DomainObject = New-Object System.DirectoryServices.DirectoryEntry(("LDAP://" + $Domain),$User,($Credential.GetNetworkCredential().password))
If ($DomainObject.name -eq $null)
    {
     Write-Host "Authentication failed, please verify your username and password"
     Break
    }
Else
    {
     Write-Host "Successfully authenticated $User to $Domain"
     $Global:Credential = $Credential
    }


}
