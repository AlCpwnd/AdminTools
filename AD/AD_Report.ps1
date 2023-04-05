#Requires -Modules ActiveDirectory
$Users = Get-ADUser -Filter * -Properties *

class UserReport {
    [String]$Name
    [String]$samAccountName
    [String]$Path
    [Bool]$Enabled

    UserReport(
        [String]$n,
        [String]$s,
        [Array]$p,
        [Bool]$e
    ){
        $this.Name = $n
        $this.samAccountName = $s
        $this.Path = $p
        $this.Enabled = $e
    }
}

$Global:Report = foreach($User in $Users){
    $Temp = $User.DistinguishedName.Split(',') | Where-Object{$_ -notmatch "DC|$($User.Name)"}
    if($Temp.Count -gt 1){
        $OUs = $(for($i=$Temp.Length; $i -gt 0; $i--){$Temp[$i-1]}) -join '\' -replace 'OU=','' -replace 'CN=',''
    }else{
        $OUs = $Temp.Replace('OU=','').Replace('CN=','')
    }
    [UserReport]::new(
        $User.Name,
        $User.UserPrincipalName,
        $OUs,
        $User.Enabled
    )
}

$Path = "$PSScriptRoot\AdReport.csv"
$Global:Report | Export-Csv -Path $Path -NoClobber -NoTypeInformation -Delimiter ';'
Write-Host "Report exported to: $Path"
Write-Host 'Report also saved under the variable: $Global:Report'

<#
    .SYNOPSIS
    Returns a list of existing AD users.

    .DESCRIPTION
    Returns a list of existing AD users with the following information:
    - DisplayName
    - Login
    - OU path
    - If the user is enabled.

    .INPUTS
    None. You cannot pipe objects to AdReport.ps1

    .OUTPUTS
    None.

    .LINK
    Get-ADUser
#>