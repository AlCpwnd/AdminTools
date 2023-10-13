param(
    [String]$OU,
    [Int32]$LogonTreshold,
    [Int32]$InactiveTreshold,
    [Switch]$TestRun
)

#Requires -Modules ActiveDirectory -RunAsAdministrator

#=Parameters:=====================================================#

# Organizational Unit you want to verify.
# Leaving it empty will recover all AD users.
$OU = ""
# Amount of days without user login activity before it is disabled.
# Leaving it as 0 will skip the test.
$LogonTreshold = 0
# Amount of days a newly created user can exist without loggin in.
# Leaving it at 0 will skip the test
$InactiveTreshold = 0
# Enabling this will only list the users instead of disabling them.
$TestRun = $true


#=Code:===========================================================#

$Parameters = @{
    Filter = {Enabled -eq $true}
    Properties = 'lastLogonDate','whenCreated'
}

if($OU){
    $Parameters.Add('SearchBase',$OU)
}

$Users = Get-ADUser @Parameters

if($LogonTreshold){
    $LogonReport = @()
    $ActiveUsers = $Users | Where-Object{$_.LastLogonDate}
    $Limit = (Get-Date).AddDays($LogonTreshold*-1)
    foreach($User in $ActiveUsers){
        if($User.LastLogonDate -lt $Limit){
            if($TestRun){
                $LogonReport += $User | Select-Object SAMAccountName,LastLogonDate
            }else{
                $User.Enabled = $false
                $User.Description += "[UserDisable.ps1:$(Get-Date -Format dd/MM/yyyy)]"
                Set-ADUser -Instance $User
            }
        }
    }
    if($TestRun){
        Write-Host "Users exceeding the logon treshold $LogonTreshold days: $($LogonReport.Count) found."
        $LogonReport | Out-Host
    }
}

if($InactiveTreshold){
    $InactiveReport = @()
    $InactiveUsers = $Users | Where-Object{-not $_.LastLogonDate}
    $Limit = (Get-Date).AddDays($InactiveTreshold*-1)
    foreach($User in $InactiveUsers){
        if($User.WhenCreated -lt $Limit){
            if($TestRun){
                $InactiveReport += $User | Select-Object SAMAccountName,whenCreated
            }else{
                $User.Enabled = $false
                $User.Description += "[UserDisable.ps1:$(Get-Date -Format dd/MM/yyyy)]"
                Set-ADUser -Instance $User
            }
        }
    }
    if($TestRun){
        Write-Host "Users exceeding the inactivity treshold $InactiveTreshold days: $($InactiveReport.Count) found."
        $InactiveReport | Out-Host
    }
}

<#
    .SYNOPSIS
    Script disabling inactive or unused users.

    .DESCRIPTION
    Script goes over the given OU/AD and either lists or disables the users
    corresponding to the given tresholds.

    .INPUTS
    None. You can't pipe objects into this script.

    .OUTPUTS
    If running using the $TestRun script, a list of the affected users will
    be outputted onto the host.

    .PARAMETER OU
    Organizational Unit you want to restrict the script to.

    .PARAMETER LogonTreshold
    Amount of days without user login activity before it is disabled.

    .PARAMETER InactiveTreshold
    Amount of days a newly created user can exist without loggin in.

    .PARAMETER TestRun
    Enabling this will only list the users instead of disabling them.

    .EXAMPLE
    PS> UserDisable.ps1 -OU "OU=Finance,OU=UserAccounts,DC=Contosco,DC=local" -LogonTreshold 30

    .EXAMPLE
    PS> UserDisable.ps1 -InactiveTreshold 60 -TestRun

    .LINK
    Get-ADUser

    .LINK
    Send-MailMessage

    .LINK
    Get-GPOReport
#>