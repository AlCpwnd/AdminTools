Function 7zSubFolders{
    [alias('7zsf')]
    param(
        [String]$Path
    )
    if(!(Get-Alias -Name '7z' -ErrorAction SilentlyContinue)){
        if(Test-Path 'C:\Program Files\7-Zip\7z.exe'){
        New-Alias -Name '7z' -Value 'C:\Program Files\7-Zip\7z.exe' -Scope Local
        }else{
        throw "7zip isn't installed"
        }
    }
    if(!$Path){
        $Path = (Get-Location).Path
    }
    $Folders = Get-ChildItem -Path $Path -Directory
    foreach($Folder in $Folders){
        7z a "$Path\$($Folder.Name).zip" "$($Folder.FullName)\*"
        Write-Host '# Done:' -ForeGroundColor Green -NoNewLine
        Write-Host $Folder.FullName
    }
    <#
        .SYNOPSIS
        Compresses all subfolders of the given folder.

        .DESCRIPTION
        Makes an archive for each subfolder in a given folder using 7zip.
        The function will verify 7zip is installed en exit if not detected.

        .PARAMETER Path
        Path to the starting directory of the function. All subfolders of that directory will be archived.

        .INPUTS
        None, you cannot pipe data into this function.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> 7zSubFolders

        .EXAMPLE
        PS> 7zSubFolders -Path E:\Data\

        .LINK
        Get-ChildItem
    #>
}

Function CompressSubFolders{
    [alias('csf')]
    param(
        [String]$Path
    )
    if(!$Path){
        $Path = (Get-Location).Path
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
} 
function Surface-ZipArchives{
    param(
        [String]$Path
    )
    if(!$Path){
        $Path = (Get-Location).Path
    }
    if($Path[-1] -ne "\"){
        $Path += "\"
    }
    $Archives = Get-ChildItem -Path "$Path\*.zip" -Recurse
    foreach($Archive in $Archives){
        $FileName = $Archive.FullName.Replace("$Path","").Split("\") -Join "_-_"
        $NewName = "$Path$FileName"
        Move-Item $Archive.FullName $NewName
    Write-Host '# Moved:' -ForeGroundColor Green -NoNewLine
    Write-Host $Archive.FullName
    }
    <#
        .SYNOPSIS
        Moves 'zip' archives find un subfolders to the current location.

        .DESCRIPTION
        Moves found zip archives found in the subfolders to the current location,
        renaming them in accordance to their relative location.

        .PARAMETER Path
        Path to the starting directory of the function. All arhives contained within the subfolders
        will be brought up to this path.

        .INPUTS
        None, you cannot pipe data into this function.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> Surface-ZipArchives

        .EXAMPLE
        PS> Surface-ZipArchives -Path E:\Data\

        .LINK
        Get-ChildItem

        .LINK
        Move-Item
    #>
}