# AdminTools
Sripts meant to facilitate day to day admnistration

## Active Directory

### AD_UserInfo.ps1
Meant for completing existing AD user information.

#### Arguments:
- Import : Path to the CSV file with the information you want to import.
- Template : By default return a template array with all available fields. Can be used in combination with :
    - User : Will return an array with the information of the given user.
    - Group : Will return an array with the information of all members and submembers of the given group.

## File Management

### Explorer_FolderInheritance.ps1

Will list all subfolders for which security permissions enhiritance has been disabled.
For more info run:
```
Get-Help Folder_Inheritance.ps1 -Full
```