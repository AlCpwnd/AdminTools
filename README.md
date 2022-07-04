# AdminTools
Sripts meant to facilitate day to day admnistration

## Active Directory

### AD_Import.ps1
Meant for completing existing AD user information.

#### Arguments:
- Path : Csv filepath containing the user information
- Template : Returns an array containging all the fields that can be completed / modified. If used in conjuction with `User` or `Group` , it will return an array filled with the user or groupmembers information.

## File Management

### Explorer_FolderInheritance.ps1

Will list all subfolders for which security permissions enhiritance has been disabled.
For more info run:
```
Get-Help Folder_Inheritance.ps1 -Full
```