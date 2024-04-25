param(
    [String]$Path
)
if(!$Path){
    $Path = $PSScriptRoot
}
$Folders = Get-ChildItem -Path $Path -Directory
$i = 0
$iMax = $Folders.count
foreach($Folder in $Folders){
    Write-Progress -Activity "Generating archives [$i/$iMax]" -Status $Folder.Name -PercentComplete (($i/$iMax)*100)
    Compress-Archive -Path "$($Folder.FullName)\*" -DestinationPath "$Path\$($Folder.Name).zip"
    $i++
}
<#
    .SYNOPSIS
    Compresses all subfolders of the given folder.

    .DESCRIPTION
    Makes an archive for each subfolder in a given folder.

    .PARAMETER Path
    Path to the starting directory of the function. All subfolders of that directory will be archived.

    .INPUTS
    None, you cannot pipe data into this function.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> CompressSubFolders

    .EXAMPLE
    PS> CompressSubFolders -Path E:\Data\

    .LINK
    Get-ChildItem

    .LINK
    Compress-Archive
#>
