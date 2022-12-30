param(
    [Parameter(Position=0)][String]$ShareName,
    [Switch]$All
)

if($ShareName){
    $Shares = Get-SmbShare -Name $ShareName | Where-Object{$_.ShareType -eq "FileSystemDirectory" -and (Test-Path $_.Path)}
}else{
    $Shares = Get-SmbShare | Where-Object{$_.ShareType -eq "FileSystemDirectory" -and (Test-Path $_.Path)}
}

class SharePerm{
    [String]$Share
    [String]$Path
    [String]$Identity
    [Array]$Permissions
    SharePerm(
        [String]$s,
        [String]$p,
        [String]$i,
        [Array]$Perm
    ){
        $this.Share = $s
        $this.Path = $p
        $this.Identity = $i
        $this.Permissions = $Perm
    }
}

$Report = foreach($Share in $Shares){
    if(!$All){
        $Permissions = (Get-Acl $Share.Path).Access | Where-Object{$_.IdentityReference -match $Env:USERDOMAIN}
    }else{
        $Permissions = (Get-Acl $Share.Path).Access
    }

    foreach($Permission in $Permissions){
        [SharePerm]::new(
            $Share.Name,
            $Share.Path,
            $Permission.IdentityReference,
            $Permission.FileSystemRights
        )
    }
}

return $Report

<#
    .SYNOPSIS
    Lists shares and permissions on it.

    .DESCRIPTION
    Lists existing permissions on all 

    .PARAMETER ShareName
    Name of the share for which you want to list the permissions. By default, all shares will be checked.

    .PARAMETER All
    Switch requesting for all permissions to be returned. The script will only return domain user/group permissions by default.

    .INPUTS
    None, you cannot pipe data into this script.

    .OUTPUTS
    Array containing all permissions of the given folders.

    .EXAMPLE
    PS> WE_SharePermissionList.ps1

    .LINK
    Get-SMBShare

    .LINK
    Get-Acl
#>