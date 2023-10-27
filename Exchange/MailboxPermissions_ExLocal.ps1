param(
    [String]$Path,
    [Switch]$IgnoreDiscovery
)

# Script meant for reporting mailbox permissions.
$Mailboxes = Get-Mailbox -ResultSize Unlimited

# Cancels the script in case no mailboxes are found.
if(!$Mailboxes){
    throw 'No mailboxes found.'
}

# Skips documenting the 'DiscoverSearchMailbox'.
if($IgnoreDiscovery){
    $Mailboxes = $Mailboxes | Where-Object{$_.Name -notmatch 'DiscoverySearchMailbox'}
}

# Custom class used for generating the report.
class MbxPermission{
    [String]$Alias
    [String]$Name
    [String]$User
    [String]$Permission
    MbxPermission(
        [String]$a,
        [String]$n,
        [String]$u,
        [String]$p
    ){
        $this.Alias = $a
        $this.Name = $n
        $this.User= $u
        $this.Permission= $p
    }
}

# Main loop.
$i = 0
$iMax = $Mailboxes.Count
$Report = foreach($Mailbox in $Mailboxes){
    Write-Progress -Activity "Verifying permissions: [$i/$iMax]" -Status $Mailbox.Name -PercentComplete (($i/$iMax)*100)
    $Permissions = Get-MailboxPermission -Identity $Mailbox.Alias
    foreach($Permission in $Permissions){
        if($Permission.User -match 'NT AUTHORITY'){
            continue
        }
        $Access = $Permissions.AccessRights -join ','
        [MbxPermission]::new(
            $Mailbox.Alias,
            $Mailbox.Name,
            $Permission.User,
            $Access
        )
    }
    $i++
}

# Report export.
if(!$Path){
    $Path = "$PSScriptRoot\$(Get-Date -Format yyyyMMdd)_MailboxReport.csv" 
}elseif(Test-Path -Path $Path -PathType Container){
    $Path += "\$(Get-Date -Format yyyyMMdd)_MailboxReport.csv"
    $Path = $Path.Replace("\\","\")
}
$Report | Export-Csv -Path $Path -Encoding UTF8 -NoTypeInformation -NoClobber

<#
    .SYNOPSIS

    Lists user permissions on existing mailboxes

    .DESCRIPTION

    Will get all mailboxes within the exchange server and will 
    document the AccessRights from other users on that mailbox.

    .PARAMETER Path

    Filepath for the report.

    .PARAMETER IgnoreDiscovery

    This switch will skip documenting the 'DiscoverySearchMailbox'.

    .INPUTS

    None. You cannot pipe objects into MailboxPermissions_Ex2016.ps1 .

    .OUTPUTS

    CSV file containing the permissions.

    .EXAMPLE

    PS> MailboxPermissions_Ex2016.ps1 -Path 'C:\Temp\' -IgnoreDiscovery

    .EXAMPLE

    PS> MailboxPermissions_Ex2016.ps1 -Path 'C:\Temp\Report.csv'
    
    .LINK

    Get-Mailbox

    .LINK

    Get-MailboxPermission
#>
