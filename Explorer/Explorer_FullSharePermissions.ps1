function Get-SharesInfo{
        param(
        [Parameter(Position=0)][String]$ShareName,
        [Switch]$All
    )

    if($Computer){
        $Shares = Get-SmbShare -Name $ShareName | Where-Object{$_.ShareType -eq "FileSystemDirectory" -and (Test-Path $_.Path)}
    }else{
        $Shares = Get-SmbShare | Where-Object{$_.ShareType -eq "FileSystemDirectory" -and (Test-Path $_.Path)}
    }

    $Report = foreach($Share in $Shares){
        if(!$All){
            $Permissions = (Get-Acl $Share.Path).Access | Where-Object{$_.IdentityReference -match $Env:USERDOMAIN}
        }else{
            $Permissions = (Get-Acl $Share.Path).Access
        }
        foreach($Permission in $Permissions){
            [PSCustomObject]@{
                Share = $Share.Name
                Path = $Share.Path
                Identity = $Permission.IdentityReference
                Permission = $Permission.FileSystemRights
            }
        }
    }

    return $Report
}

function Get-InheritanceBrokenFolders {
    param(
        [Parameter(Position=0)]
        [string]$Path
    )
    Write-Host "`n`t[i]Recovering folders"
    if($Path){
        $Folders = Get-ChildItem $Path -Recurse | Where-Object{$_.PSIsContainer}
    }else{    
        $Folders = Get-ChildItem -Recurse | Where-Object{$_.PSIsContainer}
    }
    $i = 0
    $iMax = $Folders.Count
    $Report = foreach($Folder in $Folders){
        Write-Progress -Activity "Verifying rights [$i/$($iMax)]" -Status $Folder.Name -PercentComplete ($i/$iMax*100)
        $Access = Get-Acl -Path $Folder.FullName | Select-Object -ExpandProperty Access
        $InheritedPermission = ($Access | Where-Object{$_.IsInherited}).Count
        if(!$InheritedPermission){
            $Folder.FullName
        }
        $i++
    }
    return $Report
}

