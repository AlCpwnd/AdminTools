param(
    [Array]$UserExceptions,
    [Switch]$ExplodeGroups,
    [Switch]$Silent
)

#Requires -Module ActiveDirectory,SmbShare

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
        Show-Status error "Invalid folder path : $FolderPath" -ForegroundColor Red
        return
    }

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

    $Folders = Get-ChildItem $Path -Recurse | Where-Object{$_.PSIsContainer}

    $i = 0
    $iMax = $Folders.Count
    $Report = foreach($Folder in $Folders){
        Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Status $Folder.Name -PercentComplete ($i/$iMax*100) -Id 1 -ParentId 0
        $Access = Get-Acl -Path $Folder.FullName | Select-Object -ExpandProperty Access
        $InheritedPermission = ($Access | Where-Object{$_.IsInherited}).Count
        if(!$InheritedPermission){
            $Folder.FullName
        }
        $i++
    }
    Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Id 1 -ParentId 0 -Status $Folder.Name -Completed
    return $Report
}

$ShareExceptions = "\$","NETLOGON","SYSVOL"
$Shares = Get-SmbShare | Where-Object{$_.ShareType -eq "FileSystemDirectory" -and $_.Name -notmatch $($ShareExceptions -join "|")}

$j = 0
$jMax = $Shares.Count
Show-Status info "$jMax Share(s) found"

$Report = foreach($Share in $Shares){
    Write-Progress -Activity "Verifying permission" -Status $Share.Name -Id 0 -PercentComplete (($j/$jMax)*100)
    $SharePermissions = Get-FolderPermission -FolderPath $Share.Path
    $Exceptions = Get-InheritanceBrokenFolders -Path $Share.Path
    if($Exceptions){
        $SharePermissions += foreach($Exception in $Exceptions){
            Show-Status info "Inheritance break found : $Exception" 
            Get-FolderPermission -FolderPath $Exception
        }
    }
    $SharePermissions
    $j++
}
Write-Progress -Activity "Verifying permission" -Status $Share.Name -Id 0 -Completed

if($ExplodeGroups){
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

if($UserExceptions){
    Show-Status info "Removing UserExceptions from the report"
    $Filter = foreach($User in $UserExceptions){
        try{
            "$Env:USERDOMAIN\$((Get-ADUser $User).SamAccountName)"
        }catch{
            Show-Status error "Invalid exception : $User"
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

$Date = Get-Date -Format yyyyMMdd
$FilePath = "$PSScriptRoot\$Date`_$Env:COMPUTERNAME`_$Status.csv"
$FinalReport | Export-Csv -Path  -Delimiter ";" -NoTypeInformation
Show-Status info "Report exported to : $FilePath"