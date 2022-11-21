# PC Configuration
> PowerShell ran as admin.
Summary of commands used to configure a machine.

---

## Bloatware removal

### HP
```ps
$Apps = WMIC PRODUCT GET NAME /FORMAT:CSV | Convertfrom-Csv
$Apps | Where-Object{$_.Name -match "HP*Security*"} | %{Invoke-Expression "cmd /c wmic where `"Name like `'$($_.Name)`'`" call uninstall /nointeractive"}
```

---

### Application installation
> This is assuming [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) is installed on the device you're configuring.
```ps
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/AlCpwnd/AdminTools/main/Tests/Install.txt).Content.Split() | %{winget install -e --id $_ -h}
```

### Office Deployment
> Assuming you're using [Office Deployment Tool](https://www.microsoft.com/en-us/download/details.aspx?id=49117).
#### Office Removal
```ps
winget install -e --id Microsoft.OfficeDeploymentTool -h
Invoker-WebRequest -Uri https://raw.githubusercontent.com/AlCpwnd/AdminTools/main/Tests/OdtUninstall.xml -OutFile "C:\Program Files\OfficeDeploymentTool\Uninstall.xml"
```

#### Office Installation
> `<Path>` is referring to your own [Office config file](https://config.office.com/deploymentsettings).
```ps
winget install -e --id Microsoft.OfficeDeploymentTool -h
"C:\Program Files\OfficeDeploymentTool\setup.exe" /Download <Path>
"C:\Program Files\OfficeDeploymentTool\setup.exe" /Configure <Path>
```
