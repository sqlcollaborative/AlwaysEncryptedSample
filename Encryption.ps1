# Modified from script generated by SQL Server Management Studio at 10:27 PM on 2/5/2016
param(
	[string] $Server = "DESKTOP-LKK3AHC\CTP2016_33",
	[string] $ExtensionsApplicationLocation = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\Binn\ManagementStudio\Extensions\Application\',
	[string] $DacLocation = 'C:\Program Files (x86)\Microsoft SQL Server\130\DAC\bin\',
	[string] $AuthSchema = 'Authentication',
	[string] $AppSchema = 'Purchasing' 
)
# Load reflected assemblies
{
	[reflection.assembly]::LoadwithPartialName('System.Data.SqlClient')
	[reflection.assembly]::LoadwithPartialName('Microsoft.SQLServer.SMO')
	[reflection.assembly]::LoadwithPartialName('Microsoft.SqlServer.ConnectionInfo')
	[reflection.assembly]::LoadwithPartialName('System.Security.Cryptography.X509Certificates')
	[reflection.assembly]::LoadFile($DacLocation + 'Microsoft.SqlServer.Dac.dll')
	[reflection.assembly]::LoadFile($DacLocation + 'Microsoft.SqlServer.Dac.Extensions.dll')
	[reflection.assembly]::LoadFile($DacLocation + 'Microsoft.Data.Tools.Utilities.dll')
	[reflection.assembly]::LoadFile($DacLocation + 'Microsoft.Data.Tools.Schema.Sql.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.IdentityModel.Clients.ActiveDirectory.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.SqlServer.Management.AzureAuthenticationManagement.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.SqlServer.Management.AlwaysEncrypted.Management.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.SqlServer.Management.AlwaysEncrypted.AzureKeyVaultProvider.dll')
	[reflection.assembly]::LoadFile($ExtensionsApplicationLocation + 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.dll')
} | Out-Null
# Set up connection and database SMO objects

$sqlConnectionString = "Server=$($Server);Integrated Security=SSPI;"
$smoServerConnection = New-Object 'Microsoft.SqlServer.Management.Common.ServerConnection' ($Server)
$smoServer = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $smoServerConnection
$smoDatabase = $smoServer.Databases['AlwayEncryptedSample']
# Change encryption schema

$AEAD_AES_256_CBC_HMAC_SHA_256 = 'AEAD_AES_256_CBC_HMAC_SHA_256'

# Change table [Authentication].[AspNetUsers]
$smoTable = $smoDatabase.Tables['AspNetUsers', $AuthSchema]
$encryptionChanges = New-Object 'Collections.Generic.List[Microsoft.SqlServer.Management.AlwaysEncrypted.Types.ColumnInfo]'
$encryptionChanges.Add($(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.ColumnInfo' 'SSN', $(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionInfo' 'CEK_Auto1', ([Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionType]::Randomized), $AEAD_AES_256_CBC_HMAC_SHA_256)))
[Microsoft.SqlServer.Management.AlwaysEncrypted.Management.AlwaysEncryptedManagement]::SetColumnEncryptionSchema($sqlConnectionString, $smoDatabase, $smoTable, $encryptionChanges)

# Change table [Purchasing].[CreditCards]
$smoTable = $smoDatabase.Tables['CreditCards', $AppSchema]
$encryptionChanges = New-Object 'Collections.Generic.List[Microsoft.SqlServer.Management.AlwaysEncrypted.Types.ColumnInfo]'
$encryptionChanges.Add($(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.ColumnInfo' 'CardNumber', $(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionInfo' 'CEK_Auto1', ([Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionType]::Randomized), $AEAD_AES_256_CBC_HMAC_SHA_256)))
$encryptionChanges.Add($(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.ColumnInfo' 'CCV', $(New-Object 'Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionInfo' 'CEK_Auto1', ([Microsoft.SqlServer.Management.AlwaysEncrypted.Types.EncryptionType]::Deterministic), $AEAD_AES_256_CBC_HMAC_SHA_256)))
[Microsoft.SqlServer.Management.AlwaysEncrypted.Management.AlwaysEncryptedManagement]::SetColumnEncryptionSchema($sqlConnectionString, $smoDatabase, $smoTable, $encryptionChanges)
