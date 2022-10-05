$IsClustered=$False
$IsVirtual=$False
$VMToolsVer='N/A'
$VMToolsUpStatus='N/A'

#Get VMtools if virtual no HBA
#Is Virtual Check
If(Test-Path "C:\Progra~1\VMware\VMware~1\"){
$IsVirtual=$True
$VmPath="C:\Progra~1\VMware\VMware~1\"
}
ElseIf(Test-Path "C:\Progra~2\VMware\VMware~1\"){
$IsVirtual=$True
$VmPath="C:\Progra~2\VMware\VMware~1\"
}
#If IsVirtual is true get version
If($IsVirtual){
Push-Location $VmPath
$VMToolsVer= .\vmwaretoolboxcmd -v
$VMToolsUpStatus=.\vmwaretoolboxcmd upgrade status
Pop-Location
}


#Get Server Settings
#Service Check
$Services = Get-WmiObject -Class Win32_Service -Property Name, DisplayName, State, StartMode| Select Name, DisplayName, State, StartMode

#Get Physical or Virtual

#Get HBA Settings

#Get Nic Team Settings

#Get Installed Roles and Features

#Get installed Patches

#Get installed Applications and versions
#PowerShell Version
$PoshVer=(host).Version.Major
#MS Installer Version
$MSIVer=(Get-Childitem C:\windows\system32\msi.dll | Select-Object -ExpandProperty VersionInfo).fileversion
#OS Version
$OSCaption=$OS.Caption
$OSVer=$OS.Version
$ServicePack=($OS.ServicePackMajorVersion).ToString() + "." + ($OS.ServicePackMinorVersion).ToString()


#Get Anti-Virus Version
#Get SEP Ver
$SepPath="hklm:SOFTWARE\Symantec\Symantec Endpoint Protection\currentversion\"
If(Test-Path $SepPath){
$SEPver=(Get-ItemProperty $SepPath).productversion
$SEPhotfix=(Get-ItemProperty $SepPath).hotfixrevision}
Else{$SEPver='N/A'
$SEPhotfix='N/A'
}

#Get Veritas Version

#Get SFW Version

#Get what is used for Multi-Pathing, Storage Foundation, Power Path, DMP or SFW DMP

