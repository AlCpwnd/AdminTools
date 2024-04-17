#Requires -Runasadministrator

param(
    [Swicth]$Auto
)

Repair-WindowsImage -Online -ScanHealth -NoRestart -OutVariable DISM

if($DISM.ImageHealthState -ne 'Healthy'){
    Repair-WindowsImage -Online -RestoreHealth -NoRestart -OutVariable DISM
}


