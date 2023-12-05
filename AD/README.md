# AD

Scripts used in interaction with a Windows Active Directory and/or Domain Controller server.

## PswdChangePrompt.ps1

Script will prompt users at logon, regardless if they're within the domain network or not. Modify the __Limit__ variable within the script in accordance to your password policies.

> Disclaimer:
> This is still a work in progress, please do the necessary tests prior to applying any of the steps related to this script.

### Implementation

You'll find below a suggestion on how to implement the script within a domain/network.
These are in no way obligations, these are just how I implemented it

#### Hosting

You will need the script to be hosted somewhere onto you network. The following references will be used in the rest of the script documentation:

- `NetworkScriptPath` = \\\\YourServer\\YourShare\\AD_PswdChangePrompt.ps1 (On your server)
- `LocalScriptPath` = C:\\Scripts\\AD_PswdChangePrompt.ps1 (On the user's machine)
- `LocalScriptDirectory` = C:\\Scripts\\ (On the user's machine)

### Group Policy

All the following are within __User Configuration__. Only the fields that were modified have been documented.

- User Configuration
  - Policies
    - Administrative Templates
      - System/Logon
        - Run these programs at logon : `C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File LocalScriptPath`
  - Preferences
    - Windows Settings
      - Files
        - Source file(s) : [NetworkScriptPath](#hosting)
          - Destination file : [LocalScriptPath](#hosting)
          - Read-only : Enabled
  - Folders
    - Path : [LocalScriptDirecroty](#hosting)
      - Read-only : Enabled
      - Hidden : Enabled

## UserInfo.ps1

Meant for completing existing AD user information.

### Arguments

- Import : Path to the CSV file with the information you want to import.
- Template : By default return a template array with all available fields. Can be used in combination with :
  - User : Will return an array with the information of the given user.
  - Group : Will return an array with the information of all members and submembers of the given group.

## LogonAttempts.ps1

Recovers successful and failed logon attempts on the current or given server(s).
