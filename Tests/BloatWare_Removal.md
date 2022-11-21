# Bloatware removal

Summary of commands used to remove bloatware from computers.

## HP
> PowerShell ran as admin.
```ps
$Apps = WMIC PRODUCT GET NAME /FORMAT:CSV | Convertfrom-Csv
$Apps | Where-Object{$_.Name -match "HP*Security*"} | %{Invoke-Expression "cmd /c wmic where `"Name like `'$($_.Name)`'`" call uninstall /nointeractive"}
```
