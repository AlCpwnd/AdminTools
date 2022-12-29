#Requires -Module ActiveDirectory

<#
    Test Script meant to play around with newly discovered (for me) PowerShell classes.
#>

$OrgUnit = Get-ADOrganizationalUnit -Filter *

class OU {
    [String]$Name
    [String]$Parent
    [String]$FullName
    [String]$Domain
    [String]$OutPut
    hidden [Int]$Level
}

$OUs = foreach($OU in $OrgUnit){
    $CN = $OU.DistinguishedName.Split(",") | Where-Object{$_ -match "OU="}
    $temp = [OU]::new()
    $temp.Name = $Ou.Name
    $temp.Parent = $CN | Where-Object{$_ -notmatch $OU.Name} | Select-Object -First 1
    $temp.Domain = ($OU.DistinguishedName.Split(",") | Where-Object{$_ -match "DC="} | Foreach-Object{$_.Replace("DC=","")}) -join "."
    $temp.FullName = $CN
    $temp.Level = $CN.Count
    $temp
}

