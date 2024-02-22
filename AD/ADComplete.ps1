param(
    [String]$OU
)

Write-Verbose "Recovering users."
if($OU){
    $Users = Get-ADUser -Filter "Enabled -eq $true" -SearchBase $OU -Properties DisplayName,proxyAddresses,EmailAddress
}else{
    $Users = Get-ADUser -Filter "Enabled -eq $true" -Properties DisplayName,proxyAddresses,EmailAddress
}

$Changed = @()
Write-Verbose "Verifying users..."
foreach($User in $Users){
    $Change = $false
    if(!$User.EmailAddress){
        $User.EmailAddress = $User.SAMAccountName
        $Change = $true
    }
    if(!$User.proxyAddresses){
        $User.proxyAddresses = "SMTP:$($User.SAMAccountName)"
        $Change = $true
    }elseif(!($User.proxyAddresses | Where-Object{$_ -match $User.SAMAccountName})){
        "smtp:$($User.SAMAccountName)"
        $Change = $true
    }
    if($Change){
        $Changed += $User
        Set-ADUser -Instance $User
    }
}

if($Changed){
    Write-Host "Changed users:"
    $Changed | Select-Object DisplayName,EmailAddress,proxyAddresses
}

<#
    .SYNOPSIS
    Completes the AD users email settings.

    .DESCRIPTION
    Verifies if the EmailAddress and proxyAddresses field have been
    filled for the users within the given OU. If none are given, the
    script will check all users within the AD.

    .PARAMETER OU
    DistinguishedName of the OU from which the users need to be verified.

    .INPUTS
    None. You cannot pipe objects to ADComplete.ps1.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> .\ADComplete.ps1 -OU OU=M365 Synced,OU=Users,OU=Belgium,DC=Contosco,DC=local

    .LINK
    Get-ADUser

    .LINK
    Set-ADUser
#>