# Exchange: Exchange Online Management

Scripts meant to facilitate the management of Exchange Online.

## Add-CalendarPermission.ps1

Will automatically recover the calendar folder corresponding to the account's regional configuration and add the given user-permission to it.

Parameters:

- Identity: UPN or alias of the mailbox to which you want to add the calendar access.
- User: UPN or alias of the user for which access needs to be added.
- AccessRight: Choose from
  - Owner
  - Reviewer
  - Editor

## Exch_MailboxPermissions_ExOnline.ps1

Will return a csv-file containing all non-default permissions on all mailboxes within a tenant.
> The execution time of this script is directly proportional to the amount of mailboxes you have in your tenant. Keep that in mind.

## MailboxPermissions_ExLocal.ps1

> **Disclaimer:**
> This script has only been tested on an Exchange 2016. Commands should be similar for other versions, but class definition might not be supported.

Will return a CSV-file containing all non-default permissions on all mailboxes within the server.

## PermissionCleanup.ps1

Will remove existing permissions linked to removed users by removing permissions where the user is only shown using a SID.
Will also generate a log file containing the removed permissions, unless the `NoLogs` switch is used.
