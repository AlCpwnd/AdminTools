Add-Type -AssemblyName PresentationFramework

# Verifies if the user is a local user
if((whoami) -match (HOSTNAME)){return}

# Number of days before the expiration the prompt should show up
$Limit = 20

# Recovers current user's information
$UserInfo = net user $env:USERNAME /domain
# Isolates the line regarding the next password change
$DateString = ($UserInfo | Where-Object{$_ -match "Password expires"}).split(" ")[-2]
# Converts the isolated data to a valid DateTime format
$DateLimit = [DateTime]::parseexact($DateString, 'dd/MM/yyyy', $null)
# Calculates the time left before the change
$Days = ($DateLimit - (Get-Date)).Days

if($Days -le $Limit){
    # Generates the prompt containing the information
    [System.Windows.MessageBox]::Show("Your password expires in $Days days!`nPlsease use Ctrl+Alt+Del to change your password.","Password Expiration","Ok","Warning")
}
