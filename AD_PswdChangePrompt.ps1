Add-Type -AssemblyName PresentationFramework

# Number of days before the expiration the prompt should show up
$Limit = 20

# Backup file used if logon server is unavailable
$BuFile = "$PSScriptRoot\bu.csv"

# Verifies if the user is a local user
if((whoami) -match (HOSTNAME)){return}

# Verifies if a logon server is available
$ServerTest = Test-Connection -ComputerName $env:LOGONSERVER
# Verifies if a backup file exists
$FileTest = Test-Path -Path $BuFile

if($ServerTest){
    # Recovers current user's information
    $UserInfo = net user $env:USERNAME /domain
    # Isolates the line regarding the next password change
    $DateString = ($UserInfo | Where-Object{$_ -match "Password expires"}).split(" ")[-2]
    # Converts the isolated data to a valid DateTime format
    $DateLimit = [DateTime]::parseexact($DateString, 'dd/MM/yyyy', $null)
}elseif($FileTest){
    # Recovers the file's contents
    $FileContents = Import-Csv $BuFile -Header User,Date
    # Verifies if the file contains any information regarding the current user
    if($FileContents.User -contains $env:USERNAME){
        $DateLimit = [DateTime]$FileContents[$FileContents.User.IndexOf($env:USERNAME)].Date
    }else{
        return
    }
}else{
    Return
}

# Writes the updated data back to a file if server is available
if($FileTest -and $ServerTest){
    # Verifies if the user is already documented within the file
    if($FileContents.User -contains $env:USERNAME){
        $FileContents[$FileContents.User.IndexOf($env:USERNAME)] = $DateLimit
    }else{
        $FileContents += [PSCustomObject]@{
            User = $env:USERNAME
            Date = $DateLimit
        }
    }
}

# Calculates the time left before the change
$Days = ($DateLimit - (Get-Date)).Days

# Verifies if the remaining time is within the limit
if($Days -le $Limit){
    if($ServerTest){
        # Message if the logon server is available
        $msg = "Your password expires in $Days days.`nPlease use Ctrl+Alt+Del to change your password."
    }else{
        # Message if the logon server isn't available
        $msg = "Your password expires in $Days days.`nPlease try to do so next time your within the office."
    }
    # Generates the prompt containing the information
    [System.Windows.MessageBox]::Show($msg,"Password Expiration","Ok","Warning")
}
