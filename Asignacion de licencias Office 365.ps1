$credential = get-credential
$credential2 = Get-Credential
Import-Module MSOnline
Connect-MsolService -Credential $credential2

$Licences= Get-MsolAccountSku | where {$_.accountskuid -like "*ems*"}

$LO = New-MsolLicenseOptions -AccountSkuId wizink365:EMS -DisabledPlans "MFA_PREMIUM", "RMS_S_PREMIUM"

# Para agregar la licencia completa al grupo de usuarios de AD llamado EMSCompleto
$GrupoLicenciaEMSCompleto= (Get-MsolGroup  | where {$_.displayname -eq "EMSCompleto"}).ObjectId
$Usuarios = Get-MsolGroupMember -GroupObjectId $GrupoLicenciaEMSCompleto
foreach($Usuario in $Usuarios){
    $usuario | Set-MsolUserLicense -AddLicenses "wizink365:EMS"
}

# Para agregar la licencia completa al grupo de usuarios de AD llamado EMSnoIntune
$GrupoLicenciaEMSnoIntune= (Get-MsolGroup  | where {$_.displayname -eq "EMSnoIntune"}).ObjectId
$Usuarios = Get-MsolGroupMember -GroupObjectId $GrupoLicenciaEMSnoIntune
$EMSnoIntune = New-MsolLicenseOptions -AccountSkuId wiz1:EMS -DisabledPlans "INTUNE_A"
foreach($Usuario in $Usuarios){
    $usuario | Set-MsolUserLicense -AddLicenses "wiz365:EMS" -LicenseOptions $EMSnoIntune
}
