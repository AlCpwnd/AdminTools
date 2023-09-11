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