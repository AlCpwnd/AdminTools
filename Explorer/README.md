# Explorer: Windows File Explorer
Scripts meant to facilitate management of windows file explorer rights and their inheritance.

---

## WE_FolderInheritance.ps1
Will go over the subfolder of the given path and return the folders for which inheritence has been broken.
For more info run:
```ps
Get-Help Folder_Inheritance.ps1 -Full
```

---

## WE_SharePermissionList.ps1
Will return a report of the existing permissions on either the given share, or all existing shares on a device.

> This will only go over file shares, not printers or other shared devices.

Parameters:
- ShareName: Will return a report on the permissions of the Share with the given name.
- All: Will return a report of all existing shares.

## WE_FolderPermissions.ps1
Will go over a given path and return the permissions. Will also verify if any subfolders don't have broken inheritance.

> Disclaimer:
> This script has the same restrictions as the standard Windows explorer. If your path is longer than 254 characters, it will fail to recover the corresponding.

Parameters:
- UserExceptions: User you don't want to appear within the final report.
- ExplodeGroups: Will attempt to generate a report with the groupmembers if groups are found to be used for access. **This option will verify if the "ActiveDirectory" module is available.**
- Silent: Will show no feedback or progress during the execution.
