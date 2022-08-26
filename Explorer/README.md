# Explorer: Windows File Explorer
Scripts meant to facilitate management of windows file explorer rights and their inheritance.

---

## Explorer_FolderInheritance.ps1

Will list all subfolders for which security permissions enhiritance has been disabled.
For more info run:
```
Get-Help Folder_Inheritance.ps1 -Full
```

---

## Explorer_SharePermissions.ps1

Will return a report of the existing permissions on a Share.

> This will only go over file shares, not printers or other shared devices.

Parameters:
- ShareName: Will return a report on the permissions of the Share with the given name.
- All: Will return a report of all existing shares.

## Explorer_FullSharePermissions.ps1
Will go over all local shared folders and list all existing permissions, but will also verify if folders within the scope have the security rights broken and will do the same for those.

> Disclaimer:
> This module has the same restrictions as the standard Windows explorer. If your path is longer than 254 characters, it will fail to recover the corresponding.

Parameters:
- UserExceptions: User you don't want to appear within the final report.
- ExplodeGroups: Will attempt to generate a report with the groupmembers if groups are found to be used for access. **This option will verify if the "ActiveDirectory" module is available.**
- Silent: Will show no feedback or progress during the execution.
