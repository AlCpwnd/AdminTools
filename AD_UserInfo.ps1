#Requires -Modules ActiveDirectory
[CmdletBinding(DefaultParameterSetName = "Import")]

param(
    [Parameter(Mandatory,ParameterSetName = "Import",Position = 0)]
    [String]$Import,
    [Parameter(Mandatory,ParameterSetName = "Template")]
    [Parameter(Mandatory,ParameterSetName = "SingleUser")]
    [Parameter(Mandatory,ParameterSetName = "Group")]
    [Switch]$Export,
    [Parameter(ParameterSetName = "SingleUser")]
    [String]$User,
    [Parameter(ParameterSetName = "Group")]
    [String]$Group
)

Function New-Template{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ParameterSetName = "One")]
        [String]$User,
        [Parameter(Mandatory,ParameterSetName = "Many")]
        [String]$Group
    )
    if($User){
        try{
            $Temp = Get-AdUser $User -Properties c,co,company,HomePage,Manager,Department,city,streetaddress,Mobile,OfficePhone,WwwHomePage,PostalCode,Title
            if($Temp.Manager){
                $Manager = (Get-AdUser $Temp.Manager).SamAccountName
            }
            $Report = $Temp | Select-Object SamAccountName,Title,Department,Company,@{label="Manager";Expression={$Manager}},@{label="HomePage";Expression={$_.WwwHomePage}},@{label="Country";Expression={$_.c}},City,StreetAddress,PostalCode,Mobile,OfficePhone
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Host "`t[i]Couldn't be found in AD:`'$User`'" -ForegroundColor Yellow
        }
    }
    elseif($Group){
        try{
            $GroupMembers = Get-AdGroupMember $Group
            $Report = foreach($Member in $GroupMembers){
                Switch($Member.ObjectClass){
                    "group" {New-Template -Group $Member.SamAccountName}
                    "user" {New-Template -User $Member.SamAccountName}
                }
            }
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Host "`t[i]Group couldn't be found in AD: `'$Group`'" -ForegroundColor Yellow
        }
    }
    Else{
        $Report = [PsCustomObject]@{
            SamAccountName = "j.doe"
            Title = "System Engineer"
            Department = "Technical"
            Company = "Contosco"
            Manager = "w.smith"
            HomePage = "www.contosco.com"
            Country = "BE"
            City = "Brussels"
            StreetAddress = "Boulevard du Souverain 360"
            PostalCode = "1000"
            MobilePhone = "+32 444 11 22 33"
            OfficePhone = "+32 2 345 67 89"
        }
    }
    return $Report

    <#
    .SYNOPSIS
    Return user's information.

    .DESCRIPTION
    Will return the requested user's information.
    If a group is used, it will return all members information.
    If left empty, it'll return a default user template.
    
    .PARAMETER User
    Userprincipalname of the user you want the information of
    
    .PARAMETER Group
    Userprincipalname of the group which members you want the information of

    .INPUTS
    None. You cannot pipe objects to New-Template.

    .OUTPUTS
    Hashtable containing the user's information.

    .EXAMPLE
    PS> New-Template -User john.smith

    .EXAMPLE
    PS> New-Template -Group tech

    .EXAMPLE
    PS> New-Template
    
    .LINK
    Get-User

    .LINK
    Get-GroupMember
    #>
}

function New-Import{
    param(
        [Parameter(Mandatory)]
        [String]$Import
    )
    try{
        $csv = Import-Csv -Path $Import -ErrorAction Stop
    }catch{
        Write-Host "`t[!]Invalid file path." -ForegroundColor Red
        return
    }
    $Headers = ("SamAccountName","Title","Department","Company","Manager","HomePage","Country","City","StreetAddress","PostalCode","MobilePhone","OfficePhone")
    $Check = Compare-Object -ReferenceObject $Headers -DifferenceObject $csv.PsObject.Properties.Name
    $Properties = $csv.PsObject.Properties.Name | Select-Object -ExcludeProperty SamAccountName
    if($Check -contains "SamAccountName"){
        foreach($Entry in $csv){
            try{
                Get-User $csv.SamAccountName
                $Arguments = [PsCustomObject]@{
                    Identity = $csv.SamAccountName
                }

                foreach($Property in $Properties){
                    if($Entry.$Property){
                        $Arguments | Add-Member -NotePropertyName $Property -NotePropertyValue $Entry.$Property
                    }
                }
                Set-User @Arguments
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
                Write-Host "`t[i]User couldn't be found in AD:`'$($csv.SamAccountName)`'" -ForegroundColor Yellow
                continue
            }
        }
    }
    else{
        Write-Host "`t[!]`"SamAccountName`" is missing from the file. Please use the Template flag as an example." -ForegroundColor Red
    }
    return

    <#
    .SYNOPSIS
    Imports csv data onto users.

    .DESCRIPTION
    Completes the following user fields if fully utilised:
    - Title
    - Department
    - Company
    - Manager
    - Website
    - Country
    - City
    - Address
    - Postal Code
    - Mobile Phone Number
    - Office Phone Number

    .PARAMETER Path
    Path to the csv file containing the information

    .INPUTS
    None. You cannot pipe objects to New-Import.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> New-Import -Path .\UserInfo.csv
    
    .LINK
    Set-User
    #>
}

if($Import){
    New-Import -Path $Import
}

if($Export){
    if($User){
        $Output = New-Template -User $User
    }
    elseif($Group){
        $Output = New-Template -Group $Group
    }
    else{
        $Output = New-Template
    }
    $Return = $Output | Select-Object -Unique
    return $Return
}


<#
    .SYNOPSIS
    Complete User's information using a csv or export their information.

    .DESCRIPTION
    Will complete/replace the AD Users information with the information
    contained within the csv.
    Or 
    Puts out a report containing the indicated User(s) information.

    .PARAMETER Path
    Path to the csv file containing the information to complete.

    .PARAMETER Template
    Switch to request the exctraction of the information. Can be used
    in combination of User or Group. If used alone, will extract a default
    example to use as a template.

    .PARAMETER User
    Used in combination with Template, will extract the specified user's
    details.

    .PARAMETER Group
    Used in combination with Template, will extract the group member's
    details. (Only users part of that group)

    .INPUTS
    None. You cannot pipe objects to ADimport.ps1

    .OUTPUTS
    Hashtable containing the user's information.

    .EXAMPLE
    PS> ADimport -Path .\UserInformation.csv

    .EXAMPLE
    PS> ADimport -Template

    .EXAMPLE
    PS> ADimport -Template -User John.doe

    .EXAMPLE
    PS> ADimport -Template -Group "Employees"
    
    .LINK
    Get-GroupMember

    .Link
    Set-User
    #>