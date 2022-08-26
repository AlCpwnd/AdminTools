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

## Exch_MailboxPermissionsReport.ps1
Will return a csv-file containing all non-default permissions on all mailboxes within a tenant.
> The execution time of this script is directly proportional to the amount of mailboxes you have in your tenant. Keep that in mind.