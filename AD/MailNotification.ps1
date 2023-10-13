#Requires -Modules ActiveDirectory,GroupPolicy

# Settings : ######################################################################################
    # AD : #
        $GPOName = "Default Domain Policy" # Name of the GPO containing your password policy
        $PswdWarning = 0 # How many days before expiration the users will receive a warning (if 0 will attempt to recover it from $GPOName setting)
    # Mail : #
        $smtpServer = "contosco-com.mail.protection.outlook.com"
        $from = "noreply@contosco.com"
        $TestMail = "" # If given, will test the server setting by attempting to send a mail to the given email address
    # Logs : #
        $Log = $true # Set to $false to disable logging
        $LogPath = "" # ex: C:\Test.txt , default is $PSScriptRoot\Logs.txt

# Functions : #####################################################################################

function Add-Log{
    Param(
        [Parameter(Mandatory,Position=0)][String]$Path,
        [Parameter(Mandatory,Position=1)][String]$Msg
    )
    if($Log){
        Add-Content $Path "$(Get-Date -Format "[dd/MM/yyyy][HH:mm:ss]") $Msg"
    }
}

# Script : ########################################################################################

if($Log){
    if(!$LogPath){
        $LogPath = "$PSScriptRoot\Logs.txt"
    }
    if(!(Test-Path -Path $LogPath -PathType Leaf)){
        New-Item $LogPath -ItemType File
        Add-Content $LogPath " "
        Add-Content $LogPath "MailNotifications.ps1 Log File"
        Add-Content $LogPath " "
        Add-Content $LogPath "Generated on $(Get-Date -Format dd/MM/yyyy HH:mm)"
        Add-Content $LogPath " "
    }
    Add-Log $LogPath "Script started"
}

if(!$PswdWarning){
    try{
        [Xml]$Xml = Get-GPOReport -Name $GPOName -ReportType Xml -ErrorAction Stop
        $PswdWarning = ($Xml.GPO.Computer.ExtensionData.Extension.SecurityOptions | Where-Object{$_.KeyName -match "PasswordExpiryWarning"}).SettingNumber
        Add-Log $LogPath "Password change prompt delay found : $PswdWarning days"
    }catch{
        Add-Log $LogPath "_ERROR_: No PswdWarning defined and could not recover the limit from GPO `"$GPOName`""
        Add-Log $LogPath "Script Cancelled"
        return
    }
}

$Parameters = @{
    SmtpServer = $smtpServer
    Encoding = [System.Text.Encoding]::UTF8
    From = $from
    To = ""
    Subject = ""
    Body = ""
    bodyasHTML = $true
    Priority = "High"
}

if($TestMail){
    $Parameters.To = $TestMail
    $Parameters.Subject = "Test Mail"
    $Parameters.Body = "Configuration test mail."
    try{
        Send-MailMessage @Parameters -ErrorAction Stop
        Add-Log $LogPath "Test mail sent to : $TestMail"
    }catch{
        Add-Log $LogPath "_ERROR_: Failed to send the test mail. Please verify the configuration."
        return
    }
}

$Users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} -Properties DisplayName,msDS-UserPasswordExpiryTimeComputed,proxyAddresses,PasswordExpired | Where-Object{!$_.PasswordExpired} | Select-Object "Displayname",
@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}},
@{Name="Mail";Expression={($_.proxyAddresses | Where-Object{$_ -cmatch "SMTP"}).Split(":")[1]}}

Add-Log $LogPath "$($User.count) user(s) found. Starting password verification."

$Today = Get-Date
$MailCount = 0

foreach($User in $Users){
    if(!$User.Mail){Continue}
    Write-Host $User.Displayname
    $Days = ($User.ExpiryDate - $Today).Days
    $Days

    if($Days -le $PswdWarning){
        $Parameters.Subject = "Password expires within $Days days"
        $Parameters.Body = "
            <p>Dear $($User.DisplayName),<br>
            <p>You password expires in $Days day(s).
            In order to change it, please use Ctrl+Alt+Delete and choose `"Change Password`".<br>
            <p>Best regards,<br>
            <p>IT Support<br>
            <p> <br>
            <p>This is an automated mail, please do not reply to it.
            </P>"
        $Parameters.To = $User.Mail
        $Parameters.Body
        Send-MailMessage @Parameters
        Add-Log $LogPath "Mail sent to $($User.Mail) : $Days"
        $MailCount++
    }
}

if($MailCount){
    Add-Log $LogPath "$MailCount notification(s) sent."
}else{
    Add-log $LogPath "No notifications sent."
}

Add-Log $LogPath "Script stopped"

<#
    .SYNOPSIS
    Script sending mail notification when password is about to expire.

    .DESCRIPTION
    Sends a mail to user for which the password is about to expire.
    Also specifies the amount of days remaining.
    All parameters are directly defined within the script.
    See 'Settings' section.

    .INPUTS
    None. You can't pipe objects into this script.

    .OUTPUTS
    The script will generate logs in order to keep track of mails sent.

    .LINK
    Get-ADUser

    .LINK
    Send-MailMessage

    .LINK
    Get-GPOReport
#>