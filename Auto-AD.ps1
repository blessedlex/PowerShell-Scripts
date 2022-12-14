import-module ActiveDirectory


Function Get-ITSR{



}

Function Update-ITSR{


}

Function Test-User{
    [cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
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

Function Test-Group{
    [cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Group
    )
    Begin{}
    Process{
        $GroupExists=$Null
        Try{
            $Result = Get-ADGROUP $Group
            $GroupExists=$True
            #Update-Group
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            $GroupExists=$False
            #Update-ITSR "Can't find group"
        }
        Finally{
        $GroupExists
        }
    }        

    End{}
}
#Test-Group -group "GG-VDI-Users"
#Test-Group -group "GG-VDI-Users2"

Function Update-User{
    [cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$Group,
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$User
    )
    Begin{}
    Process{
        Try{
            Add-ADGroupMember -Identity $Group -Members $User -PassThrough
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            $GroupExists=$False
            #Update-ITSR "Can't find group"
        }
    }
    End{}



}

