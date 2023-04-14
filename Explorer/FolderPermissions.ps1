[CmdletBinding()]
param(
    [Parameter(Position=0)][String]$Path,
    [Array]$UserExceptions,
    [Switch]$ExplodeGroups
)

#|Variables|#

if(!$Path){
    $Path = $PSScriptRoot
}

#|Functions|#

function Get-FolderPermission{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)][String]$FolderPath,
        [Switch]$All
    )

    if(!(Test-Path $FolderPath -PathType Container)){
        throw "Invalid folder path: $FolderPath"
    }

    Write-Verbose "Recovering permissions for: $FolderPath"

    if(!$All){
        $Permissions = (Get-Acl $FolderPath).Access | Where-Object{$_.IdentityReference -match $Env:USERDOMAIN}
    }else{
        $Permissions = (Get-Acl $FolderPath).Access
    }

    class FolderPerm {
        [String]$Path
        [String]$Identity
        [String]$Permissions

        FolderPerm(
            [String]$p,
            [String]$i,
            [String]$perm
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
            $($Permission.FileSystemRights -join ",")
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
    Write-Verbose "Verifying inheritence for: $Path"
    $Folders = Get-ChildItem $Path -Directory -Recurse -ErrorAction SilentlyContinue

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
            Write-Warning "Couldn't recover permissions from: $($Folder.FullName)"
        }
        $i++
    }
    Write-Progress -Activity "Verifying rights [$i/$iMax]" -Id 1 -ParentId 0 -Status "Done" -Completed
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
Write-Verbose "$jMax Folder(s) found"

$Report = foreach($Folder in $Folders){
    Write-Progress -Activity "Verifying inheritence [$i/$iMax]" -Status $Folder.Name -Id 0 -PercentComplete (($j/$jMax)*100)
    $FolderPermissions = Get-FolderPermission -FolderPath $Folder.FullName
    $Exceptions = Get-InheritanceBrokenFolders -Path $Folder.FullName
    if($Exceptions){
        $FolderPermissions += foreach($Exception in $Exceptions){
            Write-Verbose "Inheritance break found: $Exception" 
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
        Write-Warning "ActiveDirectory module is missing from this device"
    }else{
        class FolderPermExt {
            [String]$Path
            [String]$Group
            [String]$Identity
            [String]$Permissions
    
            FolderPermExt(
                [String]$p,
                [String]$g,
                [String]$i,
                [String]$perm
            ){
                $this.Path = $p
                $this.Group = $g
                $this.Identity = $i
                $this.Permissions = $perm
            }
        }
        $i = 0
        $iMax = $Report.Count
        $FinalReport = foreach($line in $Report){
            Write-Progress -Activity "Documenting groupmembership" -Status $line.Identity -PercentComplete (($i/$iMax)*100)
            try{
                $Group = $line.Identity.Split("\")[1]
                if($Group -eq 'Domain Users'){
                    [FolderPermExt]::new(
                        $line.Path,
                        $Group,
                        '<Domain Users>',
                        $line.Permissions
                    )
                    continue
                }
                $Members = Get-ADGroupMember -Identity $Group -ErrorAction Stop
                foreach($User in $Members){
                    [FolderPermExt]::new(
                        $line.Path,
                        $Group,
                        "$Env:USERDOMAIN\$($User.SamAccountName)",
                        $line.Permissions
                    )
                }
            }catch{
                [FolderPermExt]::new(
                    $line.Path,
                    "<Direct_Access>",
                    "$Env:USERDOMAIN\$($User.SamAccountName)",
                    $line.Permissions
                )
            }
            $i++
        }
        $Report = $FinalReport
    }
}

if($UserExceptions){
    Write-Verbose "Removing UserExceptions from the report"
    $Filter = foreach($User in $UserExceptions){
        try{
            "$Env:USERDOMAIN\$((Get-ADUser $User).SamAccountName)"
        }catch{
            Write-Warning "Invalid exception: $User"
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
    $FilePath = "$PSScriptRoot\$Date`_$Status`_$(($Path.Split("\")|Where-Object{$_ -ne `"`"})[-1]).csv"
    $FinalReport | Export-Csv -Path $FilePath -Delimiter ";" -NoTypeInformation
    Write-Verbose "Report exported to: $FilePath"
}catch{
    $Global:FullSharePermissions = $FinalReport
    Write-Warning "Export attempt failed. Report saved under variable '`$FullSharePermissions'"
}

<#
    .SYNOPSIS
    Lists folders permissions.

    .DESCRIPTION
    Lists existing permissions on all first level subfolders. Will also verify if if any subfolders have broken inheritance.

    .PARAMETER Path
    Parent folder of which you want to verify the subfolders of.

    .PARAMETER ExplodeGroups
    Will return a report with the group members in addition to the group names. Will require the ActiveDirectory module to be installed.

    .INPUTS
    None, you cannot pipe data into this script.

    .OUTPUTS
    Array containing all permissions of the given folders.

    .EXAMPLE
    PS> WE_FolderPermission.ps1

    .LINK
    Get-ChildItem

    .LINK
    Get-Acl
#>