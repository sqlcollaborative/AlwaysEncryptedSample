# Modified from script generated by SQL Server Management Studio at 10:27 PM on 2/5/2016

#Requires -Modules sqlserver

[cmdletbinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string] $ConnectionString,
    [string] $MasterKeyDNSName = "CN=Always Encrypted Sample Cert",
    [switch] $RemoveExistingCerts,
    [switch] $ExportCertificate,
    [switch] $ExportCertificateKeys,
    [string] $MasterKeySQLName = "AlwaysEncryptedSampleCMK",
    [string] $AuthColumnKeyName = "AuthColumnsKey",
    [string] $AppColumnKeyName = "AppColumnsKey",
    [string] $LogColumnKeyName = "LogColumnsKey"
)

try {
    $smoDatabase = Get-SqlDatabase -ConnectionString $ConnectionString
}
catch {
    Write-Error $_
    break
}

if ($RemoveExistingCerts) {
    Write-Verbose "Removing All Existing Certificates Named $($MasterKeyDNSName)"
    $existingColumns = Get-SqlColumnEncryptionKey -InputObject $smoDatabase
    $existingColumns | ForEach-Object {
        Remove-SqlColumnEncryptionKey -Name $_.Name -InputObject $smoDatabase
    }
    Remove-SqlColumnMasterKey -Name $MasterKeySQLName -InputObject $smoDatabase
    Get-ChildItem Cert:\CurrentUser\My | Where-Object subject -eq $MasterKeyDNSName | Remove-Item
}

$Cert = (Get-ChildItem Cert:\CurrentUser\My | Where-Object subject -eq 'CN=Always Encrypted Sample Cert') | Select-Object Thumbprint -First 1
if ($Cert) {
    Write-Verbose "Certificate `"$($MasterKeyDNSName)`" Already exists"
}
else {
    Write-Host "Creating Self Signed Certificate `"$($MasterKeyDNSName)`""
    $Cert = New-SelfSignedCertificate `
        -Subject $MasterKeyDNSName `
        -CertStoreLocation Cert:\CurrentUser\My `
        -KeyExportPolicy Exportable `
        -Type DocumentEncryptionCert `
        -KeyUsage DataEncipherment `
        -KeySpec KeyExchange
    $CmkPath = "Cert:\CurrentUser\My\$($cert.ThumbPrint)"
    Write-Verbose "Column Master Key Certificate Path: $($CmkPath)"
}

if ($ExportCertificate) {
    Get-ChildItem Cert:\CurrentUser\My |
    Where-Object subject -eq "CN=Always Encrypted Sample Cert" |
    Export-Certificate -FilePath "$($MasterKeySQLName).cer" | Out-Null
}

if ($ExportCertificateKeys) {
    Get-ChildItem Cert:\CurrentUser\My |
    Where-Object subject -eq "CN=Always Encrypted Sample Cert" |
    Export-PfxCertificate -FilePath "$($MasterKeySQLName).pfx" -Password (ConvertTo-SecureString -String "1234" -Force -AsPlainText) | Out-Null
}

if ($smoDatabase.ColumnMasterKeys['AlwaysEncryptedSampleCMK']) {
    Write-Warning "Master Key Reference $($MasterKeySQLName) already exists in the database."
}
else {
    # Create a SqlColumnMasterKeySettings object for your column master key.
    $cmkSettings = New-SqlCertificateStoreColumnMasterKeySettings `
        -CertificateStoreLocation "CurrentUser" `
        -Thumbprint $Cert.Thumbprint

    New-SqlColumnMasterKey -Name $MasterKeySQLName -InputObject $smoDatabase -ColumnMasterKeySettings $cmkSettings | Out-Null
}

$ExistingColumnKeys = $smoDatabase.ColumnEncryptionKeys
@($AuthColumnKeyName, $AppColumnKeyName, $LogColumnKeyName) | ForEach-Object {
    if ($ExistingColumnKeys[$_]) {
        Write-Warning "Column Encryption Key already $_ exists."
    }
    else {
        $smoDatabase | New-SqlColumnEncryptionKey `
            -ColumnMasterKey $MasterKeySQLName `
            -Name $_ | Out-Null
    }
}
