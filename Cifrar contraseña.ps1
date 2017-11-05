Param(
    [string] $Password,
    [string] $FileName
)

$password = $Password | ConvertTo-SecureString -asPlainText -Force
$secureStringText = $password| ConvertFrom-SecureString 
Set-Content $FileName $secureStringText
