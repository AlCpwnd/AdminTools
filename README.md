# AdminTools
Sripts meant to facilitate day to day admnistration. 

They have been seperated into distinct categories as to facilitate browsing.
Each directory has its own Readme-file with more detailed information regarding its contents and use.
If specific modules are needed for the execution of the script, they will be specified within the script [run parameters](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-7.2).

---
## AD: Windows Active Directory
Scripts used in interaction with a Windows Active Directory and/or Domain Controller server.

Current scripts:
- AD_MailNotification.ps1
    - Will send a mail to user for which their password is about to expire.
- AD_PswdChangePrompt.ps1
    - Script meant to show an explicit prompt to users at logon if their password is about to expire.
- AD_UserInfo.ps1
    - Script meant to complete existing AD user information.
    - Also allow the export of existing data.

---
## Exchange: Exchange Online Management
Scripts meant to facilitate the management of Exchange Online.

Current scripts:
- Add-CalendarPermission.ps1
    - Simple script to add permissions to a calendar. Will automatically resolve the calendar name depending on the regional settings.
- Exch_MailboxPermissionsReport.ps1
    - Returns a report of all permissions users have on existing mailboxes
- PermissionCleanup.ps1
    - Removes mailox- and recipient-permissions for users that no longer exist within the Azure Active Directory

---
## Explorer: Windows File Explorer
Scripts meant to facilitate management of windows file explorer rights and their inheritance.

Current scripts:
- WE_FolderInheritance.ps1
    - Returns a list of all folders for which the permission inheritance has been broken.
- WE_SharePermissionList.ps1
    - Will return an array detailing the permissions on all existing shares of the current server.
- WE_FolderPermissions.ps1
   - Will go over the given path's child folders and return an array of their security permissions.
   - If one of the children has broken inheritance, an additionnal entry will be made for that folder in the report.

---
