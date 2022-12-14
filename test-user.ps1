Function Test-User{
    [cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True)]
    [string]$User
    )
    Begin{}
    Process{
        $UserExists=$Null
        Try{
            $Result = Get-ADUSER $USER
            $UserExists=$True
            #Test-Group
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            $UserExists=$False
            #Update-ITSR "Can't find user"
        }
        Finally{
        $UserExists
        }
    }        

    End{}
}