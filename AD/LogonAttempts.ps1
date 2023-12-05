#Requires -RunAsAdministrator

param(
    [Parameter()]
    [Array]
    $Servers
)

$Parameters = @{
    LogName = 'Security'
    InstanceId = 4624,4625
}

if($Servers){
    $iMax = $Servers.Count
    $i = 0
    $Parameters | Add-Member -MemberType NoteProperty -Name ComputerName -Value ''
    foreach($Server in $Servers){
        Write-Progress -Activity 'Generating Report' -Status $Server -PercentComplete (($i/$iMax)*100)
        if(!(Test-Connection -ComputerName $Server)){
            Write-Host "Cannot reach: $Server"
        }else{
            $Parameters.ComputerName = $Server
            $Temp = Get-EventLog @Parameters
            if(!$Temp){
                Write-Host "No logs found for: $Server"
            }else{
                $Logs = foreach($Log in $Temp){
                    $TempLog = $Log | Select-Object EventID,MachineName,Data,Index,Category,CategoryNumber,EntryType,@{l='Message';e={$_.Message}},Source,ReplacementStrings,InstanceId,TimeGenerated,TimeWritten,UserName,Site,Container
                    $AccountInfo = (($Log.Message.Split([System.Environment]::NewLine) | Where-Object{$_ -match 'Account Name:|Account Domain:'})[3,2] | ForEach-Object{($_ -split ':')[1].Trim()}) -join '\'
                    $TempLog.Message = $AccountInfo
                    $TempLog
                }
                $Date = Get-Date -Format yyyyMMdd
                $FilePath = "$PSScriptRoot\LogonAttemps_$Server`_$Date.csv"
                $Logs | Export-Csv -Path $FilePath -NoClobber -NoTypeInformation
                Write-Host "Logs for $Server exported to: $FilePath"
            }
        }
        $i++
    }
}else{
    $Temp = Get-EventLog @Parameters
    if(!$Temp){
        Write-Host "No logs found for: $Server"
    }else{
        $Logs = foreach($Log in $Temp){
            $TempLog = $Log | Select-Object EventID,MachineName,Data,Index,Category,CategoryNumber,EntryType,@{l='Message';e={$_.Message}},Source,ReplacementStrings,InstanceId,TimeGenerated,TimeWritten,UserName,Site,Container
            $AccountInfo = (($Log.Message.Split([System.Environment]::NewLine) | Where-Object{$_ -match 'Account Name:|Account Domain:'})[3,2] | ForEach-Object{($_ -split ':')[1].Trim()}) -join '\'
            $TempLog.Message = $AccountInfo
            $TempLog
        }
        $Date = Get-Date -Format yyyyMMdd
        $FilePath = "$PSScriptRoot\LogonAttemps_$Date.csv"
        $Logs | Export-Csv -Path $FilePath -NoClobber -NoTypeInformation
        Write-Host "Logs for $Server exported to: $FilePath"
    }
}

<#
.SYNOPSIS
Recovers authentication logs.

.DESCRIPTION
Gets the logs related to logon attempts from the local or remote 
computer and generates a CSV regrouping them with the username.

.PARAMETER Servers
List of servers you want to export the logs of.
Will generate an individual report for each server.

.INPUTS
None. You cannot pipe objects to LogonAttempts.ps1.

.OUTPUTS
Locations of the generated CSV report(s).

.EXAMPLE
PS> .\LogonAttempts.ps1
Logs for Windows-WS01 exported to: C:\Users\John\Desktop\LogonAttemps_20231205.csv

.EXAMPLE
PS> .\LogonAttempts.ps1 -Servers DC01,DC02,FS01,RDS01
Logs for DC01 exported to: C:\Users\John\Desktop\LogonAttemps_DC01_20231205.csv
Logs for DC02 exported to: C:\Users\John\Desktop\LogonAttemps_DC02_20231205.csv
Logs for FS01 exported to: C:\Users\John\Desktop\LogonAttemps_FS01_20231205.csv
Logs for RDS01 exported to: C:\Users\John\Desktop\LogonAttemps_RDS01_20231205.csv

.LINK
Get-EventLog
#>