#####
# Connect to exchange-online and convert the mailbox to shared.
#####

$user = Read-Host -Prompt "Enter email address of user to be disabled"
Connect-ExchangeOnline

$isShared = Get-Mailbox -Identity $user | select -ExpandProperty isShared

if ($isShared -eq 'False') {
	Set-Mailbox -Identity $user -Type Shared
	write-host 'Converting mailbox to shared, please wait.'
	start-sleep 2
} else {
	write-host 'Mailbox already converted to shared, please wait.'
	start-sleep 2
}
# Disconnect 
Disconnect-ExchangeOnline -Confirm:$false

#####
# Connect to AzureAD and block sign in
#####

Connect-AzureAD -InformationAction SilentlyContinue -LogLevel None
start-sleep 2

$status = Get-AzureADUser -ObjectId $user | select -ExpandProperty AccountEnabled

if ($status -eq 'True') {
	#block account sign in on Azure.
	Set-AzureADUser -ObjectID $user -AccountEnabled $false
	write-host 'Account is now blocked.'
	start-sleep 2
} else {
	write-host 'Account is already blocked, skipping.'
	start-sleep 2	
}

# Disconnect 
Disconnect-AzureAD -Confirm:$false -InformationAction SilentlyContinue

#####
# Remove licenses & connect to MsolService
#####

#$user = Read-Host -Prompt "Enter email address of user to be disabled"

Connect-MsolService
start-sleep 1
$isLicensed = Get-MsolUser -UserPrincipalName $user | select -ExpandProperty isLicensed
	
if ($isLicensed -eq 'True') {
	$licenses = Get-MsolUser -UserPrincipalName $user | select -ExpandProperty Licenses | select -ExpandProperty AccountSkuId
	Set-MsolUserLicense -UserPrincipalName $user -RemoveLicenses $licenses
	write-host 'Account is now unlicensed.'
	start-sleep 2
} else {
	write-host 'User is already unlicensed, skipping.'
	start-sleep 2
}

# Disconnect 
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()