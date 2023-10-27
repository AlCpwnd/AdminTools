param(
    [String]$Path
)

#Requires -Modules ExchangeOnlineManagement

try{
    $Mailboxes = Get-EXOMailbox -ResultSize Unlimited
}catch{
    Connect-ExchangeOnline
    $Mailboxes = Get-EXOMailbox -ResultSize Unlimited
}

$i = 0
$iMax = $Mailboxes.Count

$Exceptions = "Discovery","AUTHORITY\\SELF"

$Report = foreach($Mailbox in $Mailboxes){
    Write-Progress -Activity "Documenting permissions[$i/$iMax]" -Status $Mailbox.PrimarySmtpAddress -Id 0 -PercentComplete (($i/$iMax)*100)
    $Permissions = Get-EXOMailboxPermission -Identity $Mailbox.Alias
    foreach($Access in $Permissions){
        if($Access.User -match ($Exceptions -join "|")){
            Continue
        }
        [PSCustomObject]@{
            Name = $Mailbox.Name
            Email = $Mailbox.PrimarySmtpAddress
            Type = $Mailbox.RecipientTypeDetails
            User = $Access.User
            Permissions = $Access.AccessRights -join ","
        }
    }
    $i++
}
Write-Progress -Activity "Documenting permissions" -Status $Mailbox.PrimarySmtpAddress -Id 0 -Completed

if(!$Path){
    $Path = "$PsScriptRoot\$(Get-Date -Format yyyyMMdd)_MailboxPermissionReport.csv"
}elseif (Test-Path -Path $Path -PathType Container) {
    $Path += "\$(Get-Date -Format yyyyMMdd)_MailboxPermissionReport.csv"
    $Path.Replace("\\","\")
}

$Report | Export-Csv -Path $Path -Delimiter ";" -NoTypeInformation
