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

---
## Explorer: Windows File Explorer
Scripts meant to facilitate management of windows file explorer rights and their inheritance.

Current scripts:
- Explorer_FolderInheritance.ps1
    - Returns a list of all folders for which the permission inheritance has been broken.
- Explorer_FullSharePermissions.ps1
    - Improved version of Explorer_SharePermissionList.ps1
- Explorer_SharePermissionList.ps1
    - Returns a report of all permissions on existing shares and their subfolders.    

---
