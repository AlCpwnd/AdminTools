param(
    [Parameter(Position=0)][String]$Path,
    [Switch]$ExplodeGroups,
    [Switch]$Silent
)

#|Variables|#

if(!$Path){
    $Path = $PSScriptRoot
}

$Inverted = @{
    ForegroundColor = $Host.UI.RawUI.BackgroundColor
    BackgroundColor = $Host.UI.RawUI.ForegroundColor
}

#|Fuctions|#

function Print-Info{Param([Parameter(Mandatory,Position=0)][String]$Txt)if(!$Silent){Write-host "|> (i) $Txt"}}
function Print-Warning{Param([Parameter(Mandatory,Position=0)][String]$Txt)if(!$Silent){Write-host "|> /!\ $Txt" @Inverted}}

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

    class FolderPerm {
        [String]$Path
        [String]$Identity
        [Array]$Permissions

        FolderPerm(
            [String]$p,
            [String]$i,
            [Array]$perm
        ){
            $this.Path = $p
            $this.Identity = $i
            $this.Permissions = $perm
        }
    }

    $Report = foreach($Permission in $Permissions){
        [FolderPerm]::new(
            $FolderPath,
            $Permission.IdentityReference,
            $Permission.FileSystemRights
        )
    }

    return $Report

    <#
        .SYNOPSIS
        List the permissions on a given folder.

        .DESCRIPTION
        Returns an array of all permission on a given folder.

        .PARAMETER Path
        Path to the starting directory of the script. All subfolders of that directory will be verified.
        
        .LINK
        Get-ChildItem

        .LINK
        Get-Acl
    #>
}

function Get-InheritanceBrokenFolders {
    param(
        [Parameter(Mandatory,Position=0)][string]$Path
    )
    Print-Info "Verifying inheritence for: $Path"
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
                Get-InheritanceBrokenFolders -Path $Folder.FullName
            }
        }catch{
            Print-Warning "Couldn't recover permissions from: $($Folder.FullName)"
        }
        $i++
    }
    Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Id 1 -ParentId 0 -Status "Done" -Completed
    return $Report

    <#
        .SYNOPSIS
        Lists folder with broken inheritance.

        .DESCRIPTION
        Lists all subfolders that don't inhirit the rights of their parent folder and will recurse on those folders.

        .PARAMETER Path
        Path to the starting directory of the script. All subfolders of that directory will be verified.
        
        .LINK
        Get-ChildItem

        .LINK
        Get-Acl
    #>
}

#|Code|#

$Folders = Get-ChildItem $Path -Directory

$j = 0
$jMax = $Folders.Count
Print-Info "$jMax Folder(s) found"

$Report = foreach($Folder in $Folders){
    Write-Progress -Activity "Verifying inheritence" -Status $Folder.Name -Id 0 -PercentComplete (($j/$jMax)*100)
    $FolderPermissions = Get-FolderPermission -FolderPath $Folder.FullName
    $Exceptions = Get-InheritanceBrokenFolders -Path $Folder.FullName
    if($Exceptions){
        $FolderPermissions += foreach($Exception in $Exceptions){
            Print-Info "Inheritance break found: $Exception" 
            Get-FolderPermission -FolderPath $Exception
        }
    }
    $FolderPermissions
    $j++
}
Write-Progress -Activity "Verifying permission" -Status $Folder.Name -Id 0 -Completed

if($ExplodeGroups){
    $ModuleCheck = Get-Module -Name ActiveDirectory -ListAvailable
    if(!$ModuleCheck){
        Print-Warning "ActiveDirectory module is missing from this device"
    }else{
        class FolderPermExt {
            [String]$Path
            [String]$Group
            [String]$Identity
            [Array]$Permissions
    
            FolderPerm(
                [String]$p,
                [String]$g,
                [String]$i,
                [Array]$perm
            ){
                $this.Path = $p
                $this.Group = $g
                $this.Identity = $i
                $this.Permissions = $perm
            }
        }
        $FinalReport = foreach($line in $Report){
            try{
                $Members = Get-ADGroupMember $line.Identity.Value.Split("\")[1] -ErrorAction Stop
                foreach($User in $Members){
                    [FolderPermExt]::new(
                        $line.Path,
                        $line.Identity.Value.Split("\")[1],
                        "$Env:USERDOMAIN\$($User.SamAccountName)",
                        $line.Permission
                    )
                }
            }catch{
                [FolderPermExt]::new(
                    $line.Path,
                    "<Direct_Access>",
                    "$Env:USERDOMAIN\$($User.SamAccountName)",
                    $line.Permission
                )
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