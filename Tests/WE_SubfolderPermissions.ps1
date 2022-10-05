param(
    [Parameter(Position=0)][Array]$Path,
    [Switch]$ExplodeGroups,
    [Switch]$Silent
)

function Show-Status{
    param(
        [Parameter(Mandatory,Position=0)][ValidateSet("info","error")]$Type,
        [Parameter(Mandatory,Position=1)][String]$Message
    )
    if($Silent){return}
    $Date = Get-Date -Format HH:mm:ss
    switch($Type){
        "Info" {$Parameters = @{Object = "$Date (i) $Message"}}
        "Error" {$Parameters = @{Object = "$Date [!] $Message";ForegroundColor = "Red"}}
    }
    Write-Host @Parameters
}

function Get-FolderPermission{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][String]$FolderPath,
        [Switch]$All
    )

    if(!(Test-Path $FolderPath -PathType Container)){
        Show-Status error "Invalid folder path: $FolderPath"
        return
    }

    Show-Status info "Recovering permissions for: $FolderPath"

    if(!$All){
        $Permissions = (Get-Acl $FolderPath).Access | Where-Object{$_.IdentityReference -match $Env:USERDOMAIN}
    }else{
        $Permissions = (Get-Acl $FolderPath).Access
    }

    $Report = foreach($Permission in $Permissions){

        [PSCustomObject]@{
            Path = $FolderPath
            Identity = $Permission.IdentityReference
            Permission = $Permission.FileSystemRights
        }
    }

    return $Report
}

function Get-InheritanceBrokenFolders {
    param(
        [Parameter(Mandatory,Position=0)][string]$Path
    )
    try{
        Show-Status info "Recovering subfolders of: $Path"
        $Folders = Get-ChildItem $Path -Recurse -ErrorAction Stop | Where-Object{$_.PSIsContainer}
    }catch{
        Show-Status error "Couldn't verify subfolders of: $Path"
        return
    }

    $i = 0
    $iMax = $Folders.Count
    $Report = foreach($Folder in $Folders){
        Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Status $Folder.Name -PercentComplete ($i/$iMax*100) -Id 1 -ParentId 0
        try{
            $Access = Get-Acl -Path $Folder.FullName | Select-Object -ExpandProperty Access
            $InheritedPermission = ($Access | Where-Object{$_.IsInherited}).Count
            if(!$InheritedPermission){
                $Folder.FullName
            }
        }catch{
            Show-Status error "Couldn't recover permissions from: $($Folder.FullName)"
        }
        $i++
    }
    Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Id 1 -ParentId 0 -Status $Folder.Name -Completed
    return $Report
}

$Folders = Get-ChildItem -Directory

$j = 0
$jMax = $Folders.Count
Show-Status info "$jMax Folder(s) found"

$Report = foreach($Folder in $Folders){
    Show-Status info "Starting with Share: $($Folder.Name)"
    Write-Progress -Activity "Verifying permission" -Status $Folder.Name -Id 0 -PercentComplete (($j/$jMax)*100)
    $FolderPermissions = Get-FolderPermission -FolderPath $Folder.FullName
    $Exceptions = Get-InheritanceBrokenFolders -Path $Folder.FullName
    if($Exceptions){
        $FolderPermissions += foreach($Exception in $Exceptions){
            Show-Status info "Inheritance break found: $Exception" 
            Get-FolderPermission -FolderPath $Exception
        }
    }
    Show-Status info "Done with Share: $($Folder.Name)"
    $FolderPermissions
    $j++
}
Write-Progress -Activity "Verifying permission" -Status $Folder.Name -Id 0 -Completed

if($ExplodeGroups){
    $ModuleCheck = Get-Module -Name ActiveDirectory -ListAvailable
    if(!$ModuleCheck){
        Show-Status error "ActiveDirectory module is missing from this device"
    }else{
        $FinalReport = foreach($line in $Report){
            try{
                $Members = Get-ADGroupMember $line.Identity.Value.Split("\")[1] -ErrorAction Stop
                foreach($User in $Members){
                    [PSCustomObject]@{
                        Path = $line.Path
                        Group = $line.Identity.Value.Split("\")[1]
                        Identity = "$Env:USERDOMAIN\$($User.SamAccountName)"
                        Permission = $line.Permission
                    }
                }
            }catch{
                [PSCustomObject]@{
                    Path = $line.Path
                    Group = "<Direct_Access>"
                    Identity = $line.Identity
                    Permission = $line.Permission
                }
            }
        }
        $Report = $FinalReport
    }
}

if($UserExceptions){
    Show-Status info "Removing UserExceptions from the report"
    $Filter = foreach($User in $UserExceptions){
        try{
            "$Env:USERDOMAIN\$((Get-ADUser $User).SamAccountName)"
        }catch{
            Show-Status error "Invalid exception: $User"
        }
    }
    $FinalReport = $Report | Where-Object{$Filter -notcontains $_.Identity}
}else{
    $FinalReport = $Report
}

if($ExplodeGroups){
    $Status = "User"
}else{
    $Status = "Group"
}

try{
    $Date = Get-Date -Format yyyyMMdd
    $FilePath = "$PSScriptRoot\$Date`_$Env:COMPUTERNAME`_$Status.csv"
    $FinalReport | Export-Csv -Path $FilePath -Delimiter ";" -NoTypeInformation
    Show-Status info "Report exported to: $FilePath"
}catch{
    $Global:FullSharePermissions = $FinalReport
    Show-Status error "Export attempt failed. Report saved under variable '`$FullSharePermissions'"
}