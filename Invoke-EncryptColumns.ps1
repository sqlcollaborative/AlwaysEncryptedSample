﻿# Modified from script generated by SQL Server Management Studio at 10:27 PM on 2/5/2016

#Requires -Modules sqlserver

[cmdletbinding()]
param(
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string] $ConnectionString,
	[string] $AuthSchema = 'Authentication',
	[string] $AppSchema = 'Purchasing',
	[string] $LogSchema = 'Logging',
	[string] $AuthColumnKeyName = "AuthColumnsKey",
	[string] $AppColumnKeyName = "AppColumnsKey",
	[string] $LogColumnKeyName = "LogColumnsKey",
    [switch] $Script,
    [string] $LogFileDirectory = "$pwd"

)

try {
	$smoDatabase = Get-SqlDatabase -ConnectionString $ConnectionString
	$smoDatabase.DefaultSchema = $null # If we don't do this Set-SqlColumnEncryption will not respect the schema set by New-SqlColumnEncryptionSettings
}
catch {
	Write-Error $_
	break
}

$encryptionChanges = @()

# Change table [Authentication].[AspNetUsers]
if ($smoDatabase.ColumnEncryptionKeys[$AuthColumnKeyName].Length -Eq 0) {
	Write-Warning "Authentication Column Encryption Key $AuthColumnKeyName does not exist."
}
elseif ($smoDatabase.Schemas[$AuthSchema].Length -eq 0) {
	Write-Warning "Authentication Schema $AuthSchema does not exist."
}
else {
	Write-Debug "Adding ColumnEncryptionSettings for Auth Column Key $AuthColumnKeyName."
	$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName "$($AuthSchema).AspNetUsers.SSN" -EncryptionType Randomized -EncryptionKey $AuthColumnKeyName
}

# Change table [Purchasing].[CreditCards]
if ($smoDatabase.ColumnEncryptionKeys[$AppColumnKeyName].Length -Eq 0) {
	Write-Warning "Application Column Encryption Key $AppColumnKeyName does not exist."
}
elseif ($smoDatabase.Schemas[$AppSchema].Length -eq 0) {
	Write-Warning "Application Schema $AppSchema does not exist."
}
else {
	Write-Debug "Adding ColumnEncryptionSettings for App Column Key $AppColumnKeyName."
	$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName "$($AppSchema).CreditCards.CardNumber" -EncryptionType Randomized -EncryptionKey $AppColumnKeyName
	$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName "$($AppSchema).CreditCards.CCV" -EncryptionType Randomized -EncryptionKey $AppColumnKeyName
}

# Change table [Logging].[Log]
if ($smoDatabase.ColumnEncryptionKeys[$LogColumnKeyName].Length -Eq 0) {
	Write-Warning "Logging Column Encryption Key $LogColumnKeyName does not exist."
}
elseif ($smoDatabase.Schemas[$LogSchema].Length -eq 0) {
	Write-Warning "Logging Schema $LogSchema does not exist."
}
else {
	Write-Debug "Adding ColumnEncryptionSettings for Log Column Key $LogColumnKeyName."
	$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName "$($LogSchema).Log.User" -EncryptionType Deterministic -EncryptionKey $LogColumnKeyName
	$encryptionChanges += New-SqlColumnEncryptionSettings -ColumnName "$($LogSchema).Log.ClientIP" -EncryptionType Deterministic -EncryptionKey $LogColumnKeyName
}


if ($encryptionChanges.Length -eq 0) {
	Write-Warning "Could not find any column keys or schemas to encrypt."
}
else {
	Write-Verbose "Applying Column Encryption to $($encryptionChanges.Length) column(s)."
	Set-SqlColumnEncryption `
		-ColumnEncryptionSettings $encryptionChanges `
		-InputObject $smoDatabase `
		-Script:$Script `
		-LogFileDirectory $LogFileDirectory
}
