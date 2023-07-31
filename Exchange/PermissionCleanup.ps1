param(
    [Switch]$NoLogs
)

#Requires -Modules ExchangeOnlineManagement

# Will go over the existing mailboxes and remove permissions linked to SID's.
# These should be linked to users that have been removed from the tenant.

# Recovering mailboxes.
$Mailboxes = Get-EXOMailbox

$Logs = @()
$Logs += "$(Get-Date -Format "dd/MM/yyyy hh:mm:ss") [PermissionCleanup.ps1]"
$Logs += '==========================================='
$Logs += ''
$Logs += 'This fils contains all the permissions removed by the script.'
$Logs += ''

$MbxPermissions = @()
$RcptPermissions = @()

$i = 0
$iMax = $Mailboxes.Count
foreach($Mbx in $Mailboxes){
    Write-Progress -Activity 'Recovering permissions' -Status $Mbx.Name -PercentComplete (($i/$iMax)*100)
    # Recovering permissions matching SID's.
    $MbxPermissions += Get-EXOMailboxPermission -Identity $Mbx.Alias | Where-Object{$_.User -match 'S-\d-\d-\d{2}-\d{10}-\d{10}-.+'}
    $RcptPermissions += Get-RecipientPermission -Identity $Mbx.Alias | Where-Object{$_.Trustee -match 'S-\d-\d-\d{2}-\d{10}-\d{10}-.+'}
    $i++
}

if($MbxPermissions){
    $Logs += '|Removed mailbox permissions|'
    $Logs += 'Identity;User;AccessRights'
    $i = 0
    $iMax = $MbxPermissions.Count
    foreach($Permission in $MbxPermissions){
        Write-Progress -Activity 'Removing permissions' -Status $Permission.Identity -PercentComplete (($i/$iMax)*100)
        # Removes listed permissions.
        Remove-MailboxPermission -Identity $Permission.Identity -User $Permission.User -AccessRights $Permission.AccessRights -Confirm:$false
        $Logs += "$($Permission.Identity);$($Permission.User);$($Permission.AccessRights)"
        $i++
    }
}else{
    $Logs += '|No mailbox permissions found|'
}

if($RcptPermissions){
    $logs += ''
    $Logs += '|Removed recipient permissions|'
    $Logs += 'Identity;Trustee;AccessRights'
    $i = 0
    $iMax = $RcptPermissions.Count
    foreach($Permission in $RcptPermissions){
        Write-Progress -Activity 'Removing permissions' -Status $Permission.Identity -PercentComplete (($i/$iMax)*100)
        # Removes listed permissions.
        Remove-RecipientPermission -Identity $Permission.Identity -Trustee $Permission.Trustee -AccessRights $Permission.AccessRights -Confirm:$false
        $Logs += "$($Permission.Identity);$($Permission.Trustee);$($Permission.AccessRights)"
        $i++
    }
}else{
    $logs += ''
    $Logs += '|No recipient permissions found|'
}

if(!$NoLogs){
    $Date = Get-Date -Format yyyyMMdd
    $FileName = "$Date`PermissionCleanup.txt"
    $Logs | Out-File -FilePath .\$FileName
}