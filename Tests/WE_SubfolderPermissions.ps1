param(
    [Parameter(Position=0)][String]$Path,
    [Switch]$ExplodeGroups,
    [Switch]$Silent
)

if(!$Path){
    $Path = $PSScriptRoot
}

$Inverted = @{
    ForegroundColor = $Host.UI.RawUI.BackgroundColor
    BackgroundColor = $Host.UI.RawUI.ForegroundColor
}

function Print-Info{Param([Parameter(Mandatory,Position=0)][String]$Txt)if(!$Silent){Write-host "`n|> (i) $Txt"}}
function Print-Warning{Param([Parameter(Mandatory,Position=0)][String]$Txt)if(!$Silent){Write-host "`n|> /!\ $Txt" @Inverted}}

function Get-FolderPermission{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][String]$FolderPath,
        [Switch]$All
    )

    if(!(Test-Path $FolderPath -PathType Container)){
        Print-Warning "Invalid folder path: $FolderPath"
        return
    }

    Print-Info "Recovering permissions for: $FolderPath"

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
    Print-Info "Recovering subfolders of: $Path"
    $Folders = Get-ChildItem $Path -Directory -Recurse -ErrorAction Continue

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
            Print-Warning "Couldn't recover permissions from: $($Folder.FullName)"
        }
        $i++
    }
    Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Id 1 -ParentId 0 -Status "Done" -Completed
    return $Report
}

$Folders = Get-ChildItem $Path -Directory

$j = 0
$jMax = $Folders.Count
Print-Info "$jMax Folder(s) found"

$Report = foreach($Folder in $Folders){
    Print-Info "Starting with Share: $($Folder.Name)"
    Write-Progress -Activity "Verifying permission" -Status $Folder.Name -Id 0 -PercentComplete (($j/$jMax)*100)
    $FolderPermissions = Get-FolderPermission -FolderPath $Folder.FullName
    $Exceptions = Get-InheritanceBrokenFolders -Path $Folder.FullName
    if($Exceptions){
        $FolderPermissions += foreach($Exception in $Exceptions){
            Print-Info "Inheritance break found: $Exception" 
            Get-FolderPermission -FolderPath $Exception
        }
    }
    Print-Info "Done with Share: $($Folder.Name)"
    $FolderPermissions
    $j++
}
Write-Progress -Activity "Verifying permission" -Status $Folder.Name -Id 0 -Completed

if($ExplodeGroups){
    $ModuleCheck = Get-Module -Name ActiveDirectory -ListAvailable
    if(!$ModuleCheck){
        Print-Warning "ActiveDirectory module is missing from this device"
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
    Print-Info "Removing UserExceptions from the report"
    $Filter = foreach($User in $UserExceptions){
        try{
            "$Env:USERDOMAIN\$((Get-ADUser $User).SamAccountName)"
        }catch{
            Print-Warning "Invalid exception: $User"
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
    $FilePath = "$PSScriptRoot\$Date`_$Status.csv"
    $FinalReport | Export-Csv -Path $FilePath -Delimiter ";" -NoTypeInformation
    Print-Info "Report exported to: $FilePath"
}catch{
    $Global:FullSharePermissions = $FinalReport
    Print-Warning "Export attempt failed. Report saved under variable '`$FullSharePermissions'"
}