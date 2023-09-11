#Requires -Modules ActiveDirectory

#=Parameters:=====================================================#

# Organizational Unit you want to verify.
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
    Properties = 'lastLogonDate','whenCreated','distinguishedName'
}

if($OU){
    $Parameters.Add('SearchBase',$OU)
}

$Users = Get-ADUser @Parameters

if($LogonTreshold){
    $ActiveUsers = $Users | Where-Object{$_.LastLogonDate}
    $Limit = (Get-Date).AddDays($LogonTreshold*-1)
    foreach($User in $ActiveUsers){
        if($User.LastLogonDate -lt $Limit){
            if($TestRun){
                Write-Host "LogonTreshold: $($User.UserPrincipalName)" -ForegroundColor Yellow
            }else{
                $User.Enabled = $false
                $User.Description += "[UserDisable.ps1:$(Get-Date -Format dd/MM/yyyy)]"
                Set-ADUser -Instance $User
            }
        }
    }
}

if($InactiveTreshold){
    $InactiveUsers = $Users | Where-Object{-not $_.LastLogonDate}
    $Limit = (Get-Date).AddDays($InactiveTreshold*-1)
    foreach($User in $InactiveUsers){
        if($User.WhenCreated -lt $Limit){
            if($TestRun){
                Write-Host "InactiveTreshold: $($User.UserPrincipalName)" -ForegroundColor Yellow
            }else{
                $User.Enabled = $false
                $User.Description += "[UserDisable.ps1:$(Get-Date -Format dd/MM/yyyy)]"
                Set-ADUser -Instance $User
            }
        }
    }
}