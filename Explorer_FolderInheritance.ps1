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
if($Report.Count -le 30){
    Write-Host "`n`t[i]Folders found:"
    return $Report
}else{    
    $FileName = "$PSScriptRoot\$(Get-Date -Format yyyy_MM_dd)_Inheritance.txt"
    $Report | Out-File -FilePath $FileName
    Write-Host "`n`t[i]Results saved under: " -ForegroundColor Cyan -NoNewline; $FileName
    notepad.exe $FileName
}

<#
    .SYNOPSIS
    Lists folder with broken inheritance.

    .DESCRIPTION
    Lists all subfolders that don't inhirit the rights of their parent folder.

    .PARAMETER Path
    Path to the starting directory of the script. All subfolders of that directory will be verified.

    .INPUTS
    None, you cannot pipe data into this script.

    .OUTPUTS
    List containing the full folder path to the concerned folders.

    .EXAMPLE
    PS> Folder_Inheritance.ps1

    .EXAMPLE
    PS> Folder_Inheritance.ps1 -Path E:\Data\
    File.doc

    .EXAMPLE
    PS> Folder_Inheritance.ps1 E:\Data

    .LINK
    Get-ChildItem

    .LINK
    Get-Acl
#>