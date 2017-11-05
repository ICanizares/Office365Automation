## Script:      Automatización de licencias.ps1
## Versión:     1.0
## Fecha:       27/10/2017
## Descripción: Script para automatizar la asignación de licencias en base a pertenencia a grupos de AD


## USER VARIABLES ##

# Descripción #
# $FilePathBase       - Ruta base del script. Todos los ficheros relativos al script deben estar aqui. Debe incluir la contrabarra final \
# $LogFileNamePrefix  - Prefijo del fichero de log
# $CSVGroupAssignment - Nombre del fichero CSV con los nombres de grupos de AD y licencia O365 (SKU) que queremos asignar
# $TenantName         - Nombre del tenant de Office 365
# $Office365Admin     - Nombre de usuario del administrador de Office 365 (User management administrator)
# $PWDFile            - Nombre del fichero que contiene la contraseña de Office 365 securizada

$FilePathBase = "C:\Office365Automation\" 
$LogFileName = "BaseName"
$CSVGroupAssignment = "AsignacionGrupos.csv" 
$TenantName ="rtve365"
$Office365Admin = "@tenant.onmicrosoft.com"
$PWDFile = "Tenant.pwd"

## SCRIPT VARIABLES ##

$Error.Clear()
$LogFileNamePath = $FilePathBase + "LOG\" 
$CSVGroupAssignmentFullPath = $FilePathBase + "CSV\" + $CSVGroupAssignment
$PWDFileFullPath = $FilePathBase + $PWDFile

$Office365Password = Get-Content $PWDFileFullPath | ConvertTo-SecureString 
$Office365Credential = New-Object System.Management.Automation.PSCredential($Office365Admin,$Office365Password)

## SCRIPT START ##

# Crear fichero de log Si no existe
$LogFileName = $LogFileName + "_" + $(get-date -format yyyyMMdd) + ".log"
$LogFileNameFullPath = $LogFileNamePath + $LogFileName
if((Test-Path -Path $LogFileNameFullPath) -eq $false)
{
    New-Item -Path $LogFileNamePath -Name $LogFileName -ItemType File
}

Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"
Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"
Add-Content -Path $LogFileNameFullPath -Value "                       SCRIPT START - [$([DateTime]::Now)]"
Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"
Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"


# Conexión al entorno Office 365. Requiere instalar el módulo MSOnline -> PS C:\> Install-Module MSOnline
try
{
    Connect-MsolService -Credential $Office365Credential -ErrorAction Stop
}
catch
{
    Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] No se ha podido conectar con MSOnline. Comprobar usuario/contraseña."
}

# Importar los datos desde el CSV
$GroupList = Import-Csv -Path $CSVGroupAssignmentFullPath -Delimiter ";"

foreach ($Group in $GroupList)
{
    # Obtenemos los usuarios contenidos en cada unos de los grupos de AD
    try{
        $GroupId = (Get-MsolGroup  | where {$_.displayname -eq $Group.GrupoAD}).ObjectId
        $GroupUsers = Get-MsolGroupMember -GroupObjectId $GroupId
        Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] El grupo $($Group.GrupoAD) contiene $($GroupUsers.Count) usuario(s)"
    }
    catch{
        Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] No se ha podido listar el grupo de AD con nombre $($Group.GrupoAD). Comprobar que está bien escrito y que existe en AD"
        Continue
    }
    
    # Componemos el SKU Id
    $LicenseToAssign = $TenantName + ":" + $Group.Licencia

    foreach($User in $GroupUsers)
    {
        # Obtenemos las licencias de Office 365 asignadas a cada usuario
        $LicenseCurrent = (Get-MsolUser -UserPrincipalName $User.EmailAddress).licenses
        Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] El usuario $($User.EmailAddress) tiene asignadas $($LicenseCurrent.Count) licencia(s)"

        # Si el usuario no tiene licencia es posible que no tenga configurado el parámetro de localización. 
        if ($User.IsLicensed -eq $false) {$user | Set-MsolUser -UsageLocation "ES"}
        
        # Flag de control para los usuarios que no han cambiado de licencia desde la última ejecución
        $flag = 0

        # Comprobamos si el usuario ya tiene asignada la licencia y eliminamos cualquier otra que tenga asignada
        if($LicenseCurrent.Count -gt 0)
        {          
            foreach ($License in $LicenseCurrent)
            {
                # Comprobamos si el usuario ya tiene la licencia que queremos asignar y cambiamos el flag para evitar reasignar la licencia en el paso posterior
                if($License.AccountSkuId -eq $LicenseToAssign)
                {
                    Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] El usuario $($User.EmailAddress) tiene asignada la licencia correctamente"
                    $flag=1
                }
                
                # Eliminamos cualquier otra licencia que tuviera asignada
                Else
                {
                    Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] Licencia $($License.AccountSkuId) desasignada del usuario $($User.EmailAddress)"
                    $User | Set-MsolUserLicense -RemoveLicenses $License.AccountSkuId
                }
            }          
        }

        # Si el flag está a 0 asignamos la licencia, si está a 1 es que el usuario ya tiene esa licencia
        if ($flag -eq 0) 
        {
            $User| Set-MsolUserLicense -AddLicenses $LicenseToAssign
            Add-Content -Path $LogFileNameFullPath -Value "[$([DateTime]::Now)] Licencia $($License.AccountSkuId) asignada al usuario $($User.EmailAddress)"
        }
    }
}

Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"
Add-Content -Path $LogFileNameFullPath -Value "                       SCRIPT FINISH - [$([DateTime]::Now)]"
Add-Content -Path $LogFileNameFullPath -Value "**************************************************************************************************"
Add-Content -Path $LogFileNameFullPath -Value " "
Add-Content -Path $LogFileNameFullPath -Value " "
Add-Content -Path $LogFileNameFullPath -Value " "