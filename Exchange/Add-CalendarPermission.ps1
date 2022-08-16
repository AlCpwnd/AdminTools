param(
    [Parameter(Mandatory)][String]$Identity,
    [Parameter(Mandatory)][string]$User,
    [Parameter(Mandatory)][ValidateSet("Owner","Reviewer","Editor")][String]$AccessRight
)

function Get-CalendarFolder{
    param(
        [Parameter(Mandatory)][string]$User
    )
    try{
        $Calendar = (Get-EXOMailboxFolderStatistics -Identity $User -Folderscope Calendar | Where-Object{$_.FolderType -eq "Calendar"}).Identity.Replace("\",":\")
    }catch{
        Write-Host "Invalid User: $User" -ForegroundColor Red
        return
    }
    return $Calendar
}

Add-MailboxFolderPermission -Identity (Get-CalendarFolder -User $Identity) -User $User -AccessRights $AccessRight