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