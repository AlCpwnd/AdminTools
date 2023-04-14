param(
    [Parameter(Position=0)][string]$Path,
    [Int32]$Depth
)
Write-Host "`n`t[i]Recovering folders"

$Parameters = @{
    Path = ""
    Directory = $true
    Recurse = $true
}

if($Depth){
    $Parameters | Add-Member -MemberType NoteProperty -Name Depth -Value $Depth
}

if($Path){
    $Parameters.Path = $Path
}else{    
    $Parameters.Path = $PSScriptRoot
}

$Folders = Get-ChildItem @Parameters

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

    .PARAMETER Depth
    Depth of subfolder you want to run the script on. This is mainly meant to be used on large folder structures.

    .INPUTS
    None, you cannot pipe data into this script.

    .OUTPUTS
    List containing the full folder path to the concerned folders.

    .EXAMPLE
    PS> Folder_Inheritance.ps1

    .EXAMPLE
    PS> Folder_Inheritance.ps1 -Path E:\Data\

    .EXAMPLE
    PS> Folder_Inheritance.ps1 E:\Data

    
    .EXAMPLE
    PS> Folder_Inheritance.ps1 E:\Data -Depth 4

    .LINK
    Get-ChildItem

    .LINK
    Get-Acl
#>