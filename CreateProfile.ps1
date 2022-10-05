#loads scripts located in My Documents\WindowsPowerShell\Scripts\autoload
$customizedprofile='
# directory where my scripts are stored

$psdir="c:\$env:UserProfile\Documents\WindowsPowerShell\Scripts\autoload"  

# load all "autoload" scripts

Get-ChildItem "${psdir}\*.ps1" | %{.$_} 

Write-Host "Custom PowerShell Environment Loaded"
'

If (-Not(Test-Path $profile)){New-Item $profile
$customizedprofile |Add-Content $profile
}
ElseIf((get-content $profile)-eq $Null){$customizedprofile |Add-Content $profile}
Else{Write-Host "File is not empty please edit manually"}