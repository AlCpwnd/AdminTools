#Requires -RunAsAdministrator

# \_PsMenu_/

<#
	#Disclaimer:#
	"Menu" is a module by @chrisseroka which I adapted.
	https://github.com/chrisseroka/ps-menu
#>

function DrawMenu {
    param ($menuItems, $menuPosition, $Multiselect, $selection)
    $l = $menuItems.length
    for ($i = 0; $i -le $l;$i++) {
		if ($menuItems[$i] -ne $null){
			$item = $menuItems[$i]
			if ($Multiselect)
			{
				if ($selection -contains $i){
					$item = "[x] $item"
				}
				else {
					$item = "[ ] $item"
				}
			}
			if ($i -eq $menuPosition) {
				Write-Host "> $($item)" -ForegroundColor $Host.UI.RawUI.BackgroundColor -BackgroundColor $Host.UI.RawUI.ForegroundColor
			} else {
				Write-Host "  $($item)"
			}
		}
    }
}

function Toggle-Selection {
	param ($pos, [array]$selection)
	if ($selection -contains $pos){ 
		$result = $selection | where {$_ -ne $pos}
	}
	else {
		$selection += $pos
		$result = $selection
	}
	$result
}

function Menu {
    param ([array]$menuItems, [switch]$ReturnIndex=$false, [switch]$Multiselect, [array]$DefaultSelection)
    $vkeycode = 0
    $pos = 0
    $selection = $DefaultSelection | foreach{$menuItems.IndexOf($_)}
    if ($menuItems.Length -gt 0)
	{
		try {
			[console]::CursorVisible=$false #prevents cursor flickering
			DrawMenu $menuItems $pos $Multiselect $selection
			While ($vkeycode -ne 13 -and $vkeycode -ne 27) {
				$press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
				$vkeycode = $press.virtualkeycode
				If ($vkeycode -eq 38 -or $press.Character -eq 'k') {$pos--}
				If ($vkeycode -eq 40 -or $press.Character -eq 'j') {$pos++}
				If ($vkeycode -eq 36) { $pos = 0 }
				If ($vkeycode -eq 35) { $pos = $menuItems.length - 1 }
				If ($press.Character -eq ' '-or $vkeycode -eq 32) { $selection = Toggle-Selection $pos $selection }
				if ($pos -lt 0) {$pos = 0}
				If ($vkeycode -eq 27) {$pos = $null }
				if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
				if ($vkeycode -ne 27)
				{
					$startPos = [System.Console]::CursorTop - $menuItems.Length
					[System.Console]::SetCursorPosition(0, $startPos)
					DrawMenu $menuItems $pos $Multiselect $selection
				}
			}
		}
		finally {
			[System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
			[console]::CursorVisible = $true
		}
	}
	else {
		$pos = $null
	}

    if ($ReturnIndex -eq $false -and $pos -ne $null)
	{
		if ($Multiselect){
			if($Selecytion){
				return $menuItems[$selection]
			}else{
				return
			}
		}
		else {
			return $menuItems[$pos]
		}
	}
	else 
	{
		if ($Multiselect){
			return $selection
		}
		else {
			return $pos
		}
	}
}

# \_End of PsMenu_/

function Print-Info{Param([Parameter(Mandatory)][String]$Txt)Write-Host "`n(i) $Txt"}
function Print-Status{Param([Parameter(Mandatory)][String]$Txt)Write-Host "`n|>  $Txt"}

Print-Info "Recovering computer information..."
$PcInfo = Get-ComputerInfo
$Manufacturer = $PcInfo.CsManufacturer
$AppExceptions = "Realtek|Intel|Microsoft|Windows"
Print-Info "$($AppExceptions.Split("|").Count) exception(s) found:"
$AppExceptions.Split("|") | ForEach-Object{$_}

Print-Info "Recovering installed applications..."
$AppsBloatWare = Get-AppxPackage -AllUsers | Where-Object{$_.Name -notmatch $AppExceptions}
Print-Status "Please choose the applications to remove:"
$AppUninstallName = Menu -menuItems $AppsBloatWare.Name -Multiselect -DefaultSelection $($AppsBloatWare.Name | Where-Object{$_ -match $Manufacturer})
if(!$AppUninstallName){
	Print-Info "No windows applications selected for removal"
}else{
	Print-Status "Removing applications from the current profile..."
	$AppsBloatWare | Where-Object{$AppUninstallName -contains $_.Name} | Remove-AppxPackage -AllUsers | Out-Null
	Print-Status "Removing applications from the template profile..."
	Get-AppxProvisionedPackage -Online | Where-Object{$AppUninstallName -contains $_.DisplayName} | Remove-AppxProvisionedPackage -Online | Out-Null
}

Print-Info "Recovering installed software..."
$Soft = Get-WmiObject -Class Win32_Product
$SoftBloatWare = $Soft | Where-Object{$_.Name -match $Manufacturer}