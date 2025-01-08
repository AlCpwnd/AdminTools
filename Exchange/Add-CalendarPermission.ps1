param(
    [Parameter(Mandatory)][String]$Identity,
    [Parameter(Mandatory)][string]$User,
    [Parameter(Mandatory)][ValidateSet("Owner","Reviewer","Editor")][String]$AccessRight,
    [Parameter()][Bool]$Silent
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
    if(-not $Silent){Write-Host "Permission added: $Folder [$AccessRight] : $User" -ForegroundColor Green}
    Add-MailboxFolderPermission -Identity $Folder -User $User -AccessRights $AccessRight
}
elseif($Permission.AccessRights -notcontains $AccessRight){
    if(-not $Silent){Write-Host "Permission added: $Folder [$AccessRight] : $User" -ForegroundColor Yellow}
    Set-MailboxFolderPermission -Identity $Folder -User $User -AccessRights $AccessRight
}else{
    if(-not $Silent){Write-Host "Permission already exists: $Folder"}
}