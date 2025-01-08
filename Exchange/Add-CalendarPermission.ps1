param(
    [Parameter(Mandatory)][String]$Identity,
    [Parameter(Mandatory)][string]$User,
    [Parameter(Mandatory)][ValidateSet("Owner","Reviewer","Editor")][String]$AccessRight
)

function Get-CalendarFolder{
    param(
        [Parameter(Mandatory)]
        [string]$User
    )
    try{
        $Calendar = (Get-EXOMailboxFolderStatistics -Identity $User -Folderscope Calendar | Where-Object{$_.FolderType -eq "Calendar"}).Identity.Replace("\",":\")
    }catch{
        Throw "Invalid User: $User"
    }
    return $Calendar
}

$Folder = Get-CalendarFolder -User $Identity
$Permission = Get-EXOMailboxFolderPermission -Identity $Folder -User $User -ErrorAction SilentlyContinue
if(-not $Permission){
    Add-MailboxFolderPermission -Identity $Folder -User $User -AccessRights $AccessRight
}
elseif($Permission.AccessRights -notcontains $AccessRight){
    Set-MailboxFolderPermission -Identity $Folder -User $User -AccessRights $AccessRight
}