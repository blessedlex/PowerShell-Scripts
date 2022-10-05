$URL="https://xxxxxxx.com"
#$URL="https://xxxxxxx.com"

#Get Auth Token
Function Get-AuthToken{
$User=$env:USER
$Cred = Get-Credential -UserName $User -Message "Enter Password"
$Password = $Cred.GetNetworkCredential().Password

$AuthBody=@"
 { "user_name" : "$User",
   "password" : "$Password"
 }
"@
$AuthURL=$URL+"/echo/auth/login/"
Try{$Auth=Invoke-RestMethod -Uri $AuthURL -Method Post -Body $AuthBody -ErrorAction Stop}
Catch{Write-Output "Error Authenticating to AppMap"}
$AuthToken=$Auth.user.access_token
$AuthExpire=$Auth.user.expires_at
$AuthString = $User + ":"+"$AuthToken"
$AuthHeader=@{"X-AUTH-TOKEN"="$AuthString"}
$AuthProperties=@{'AuthToken'=$AuthToken;
                  'AuthHeader'=$AuthHeader; 
                  'AuthExpire'=$AuthExpire
                    
}
$global:AuthObject=New-Object -TypeName PSObject -Property $AuthProperties
Write-Host $AuthObject
}

#Check Status of Auth Token
Function Get-AuthTokenStatus{
If ($AuthObject -eq $null){Get-AuthToken}
$AuthCheckURL=$URL+"/echo/auth/check/"
$AuthCheck=Invoke-RestMethod -Uri $AuthCheckURL -Method Post -Headers ($AuthObject.AuthHeader)
Write-Output $AuthCheck
}
#Get Apps
Function Get-AppMapApps{
If ($AuthObject -eq $null){Get-AuthToken}
$AppURL=$URL+"/api/v3/appmap/applications/?format=json&username=$User&api_token="+($AuthObject.AuthToken)
$Apps=Invoke-RestMethod -Uri $AppURL -Method Get
}
#Search Apps
Function Search-AppMapApps{
If ($AuthObject -eq $null){Get-AuthToken}
$SAppURL=$URL+"/api/v3/appmap/applications/search/?format=json&username=$User&api_token="+($AuthObject.AuthToken)
$SApps=Invoke-RestMethod -Uri $SAppURL -Method Get
}
#Get UAIDs
Function Get-AppMapUAID{
If ($AuthObject -eq $null){Get-AuthToken}
$UAIDURL=$URL+"/api/v3/appmap/applications/uaids/?format=json&username=$User&api_token="+($AuthObject.AuthToken)
$UAIDs=Invoke-RestMethod -Uri $UAIDURL -Method Get
}


#Get Server
Function Get-AppMapServer{
[cmdletbinding()]
    param(
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string[]]$Server
    )
Begin{
If ($AuthObject -eq $null){Get-AuthToken}
$ServerArray=@()
}
Process{
$Server | ForEach-Object{ $ServerURL=$URL+"/api/v3/server/$_/?format=json&api_token="+($AuthObject.AuthToken)
#$ServerArray += $ServerURL
$CurrentServer=$_

    $Result=(Invoke-RestMethod -Uri $ServerURL -Method Get).result
    Try{$ServerUAIDArray=($Result|get-member -ErrorAction Stop|where {$_.MemberType -eq 'NoteProperty'}).name}
    Catch {$ServerUAID='Server not Found'}
    IF($ServerUAID -eq 'Server not Found'){
        $AppProperties=[ordered]@{'Server'=$CurrentServer;
        'UAID'=$ServerUAID}
        $AppObject=New-Object -TypeName PSObject -Property $AppProperties
        $ServerArray += $AppObject
        $ServerUAID=$null
        $ServerUAIDArray=$null
    
    }Else{
        $ServerUAIDArray|ForEach-Object{$ServerUAId=$_
            $AppProperties=[ordered]@{'Server'=$CurrentServer;
                  'UAID'=$ServerUAID;
                  'ApplicationName'=$Result.$ServerUAID.application_name;
                  'ApplicationStatus'=$Result.$ServerUAID.application_status;
                  'BusinessSegment'=$Result.$ServerUAID.business_segment; 
                  'BusinessSolution'=$Result.$ServerUAID.business_solution;
                  '1stLevelSupport'=$Result.$ServerUAID.first_level_group_support.last_name;
                  '2ndLevelSupport'=$Result.$ServerUAID.second_level_group_support.last_name;
                  '3rdLevelSupport'=$Result.$ServerUAID.third_level_group_support.last_name;
                  'LOB'=$Result.$ServerUAID.lob
                    
            }
        $AppObject=New-Object -TypeName PSObject -Property $AppProperties
        $ServerArray += $AppObject
        $ServerUAID=$null
        $ServerUAIDArray=$null
        }
        }
}
Write-Output $ServerArray
}
End{}
}
