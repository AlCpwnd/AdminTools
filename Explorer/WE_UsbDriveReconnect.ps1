# Letter you want to assign to the drive.
$DriveLetter = 'I'

# Recovers partitions without assigned drive letter.
$PartitionCheck = Get-Partition | Where-Object{$_.Type -eq 'Basic' -and !$_.DriveLetter}

if($PartitionCheck.Count -gt 1){ # Verifies if multiple partitions are found.
    Write-Host "Sript does not support multiple unassigned drives."
    return
}elseif($PartitionCheck){
    # Attemps to assign the given driveletter to the drive.
    try{ 
        # Lists the connected USB drives.
        $UsbDrive = Get-PnpDevice -PresentOnly | Where-Object{$_.InstanceId -match "USB" -and $_.Class -eq "DiskDrive"}
        # Verifies if one corresponds to the unassigned drive.
        $PartitionCheck | Where-Object{$_.DiskPath -match $UsbDrive.DeviceID.Replace('\','#')} | Set-Partition -NewDriveLetter $DriveLetter -ErrorAction Stop
    }catch{
        Write-Host "Failed to assign `"$DriveLetter`""
    }
}