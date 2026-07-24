#functions

. (Join-Path $PSScriptRoot '.env.ps1')

function Change-Hostname {
	$hostname=(Read-Host -Prompt "Choose a new hostname (ex. BigBully-001):")
	$answer = Read-Host "is $hostname acceptable y or n"
	if ($answer -eq 'Y' -or $answer -eq 'y') {
	    Write-Host 'Continuing...'                  
	} else {
	    Write-Host 'guess not, try again!:'
	    Change-Hostname
	}

	Write-Host "$(hostname) will be renamed to $hostname"
	Write-Host "...on next reboot"
	Rename-Computer -NewName "$hostname"
}

function Uninstall-McAfee {
<#
.SYNOPSIS
	Removes McAfee from workstations
.NOTES
	Author: et
#>
	Write-Output "Searching for John McAfee in the Logs..."
	
	# Find all uninstall strings in the registry
	$UninstallPaths = @(
	    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
	    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
	)
	
	# Filter for anything with McAfee in the name
	$McAfeeApps = Get-ItemProperty $UninstallPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "McAfee" -and $_.DisplayName -notmatch "WebAdvisor" }
	if ($McAfeeApps) {
		Write-Host "Found McAfeeApps"
		}else{
		Write-Host "did not find McAfee, exiting function" ; return
	}
	
	foreach ($App in $McAfeeApps) {
	    Write-Output "Attempting to uninstall: $($App.DisplayName)"
	    $UninstallString = $App.UninstallString
	
	    if ($UninstallString) {
	        Try {
	            # Handle MSI installers
	            if ($UninstallString -match "^msiexec") {
	                $CleanString = $UninstallString -replace "msiexec.exe", "" -replace "/I", "/X"
	                $CleanString += " /quiet /norestart"
	                Start-Process "msiexec.exe" -ArgumentList $CleanString -Wait -NoNewWindow
	            }
	            # Handle standard EXE uninstallers
	            else {
	                Start-Process "cmd.exe" -ArgumentList "/c $UninstallString /quiet /norestart" -Wait -NoNewWindow
	            }
	            Write-Output "Successfully uninstalled $($App.DisplayName)"
	        }
	        Catch {
	            Write-Warning "Failed to uninstall $($App.DisplayName). Error: $($_.Exception.Message)"
	        }
	    }
	}
	
	Write-Output "McAfee Native Removal Complete."
}

function Install-Applications {

	#register winget
	Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

	$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
	$settings = @{
	      network = @{
	          downloader = "wininet"
	      }
	} | ConvertTo-Json
	Write-Host "Overwriting winget settings file"
	Set-Content -Path $settingsPath -Value $settings -Force
	
	#install chrome
	Write-Host "Installing Chrome"
#	winget install --id Google.Chrome --source winget --silent --accept-package-agreements --accept-source-agreements
	$ProgressPreference='SilentlyContinue';Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:TEMP\chrome.exe" -UseBasicParsing;Start-Process "$env:TEMP\chrome.exe" "/silent /install" -Wait
	
	#install adobe
	Write-Host "Installing Adobe Reader"
	winget install --id Adobe.Acrobat.Reader.64-bit --source winget
	
	#install office using ODT
	Write-Host "Installing Office"
	#write a catch for 32bit office installation and logging
	C:\IT\sources\SETUP.EXE /configure C:\IT\sources\CONFIGURATION.XML
}

function Deploy-Bitlocker {

	Write-Host "Enabling BitLocker on C: drive"
	Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes128 -UsedSpaceOnly -RecoveryPasswordProtector
	Write-Host "Extracting recovery key"
	$recoveryKey = (Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object {$_.KeyProtectorType -eq "RecoveryPassword"} | Select-Object -ExpandProperty RecoveryPassword
	$recoveryKey | Out-File -FilePath "C:\BitLocker-Recovery-Key.txt" -Force
	Write-Host "BitLocker enabled on C:, recovery key saved to C:\BitLocker-Recovery-Key.txt"
}

function Deploy-Automate {
	Write-Host "Deploying automate"
	msiexec /i "C:\IT\sources\Agent_Install.msi" /quiet TRANSFORMS="C:\IT\sources\Agent_Install.mst"
}

function Deploy-VPN {
	#This will have to be placed in another config file
	$VpnName = "VPN"
	$ServerAddress = "vpn.example.com"
	$TunnelType = "SSTP"
	$AuthenticationMethod = "MSCHAPv2"
	$VpnEncryption = "Required"
	Add-VpnConnection -Name $VpnName -TunnelType $TunnelType -ServerAddress $ServerAddress -AuthenticationMethod $AuthenticationMethod
	rasdial.exe $VpnName (Read-Host -Prompt "User") (Read-Host -Prompt "Password")
}

function Set-AutoLogon {
	param(
		[string]$NextScript = "Deployment-Stage2.ps1"
	)

	Write-Host "Setting autologon"
	#Registry path declaration

	$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	$RegROPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

	#setting registry values

	Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String
	Set-ItemProperty $RegPath "DefaultUsername" -Value $DefaultUsername -type String
	Set-ItemProperty $RegPath "DefaultPassword" -Value $DefaultPassword -type String
	Set-ItemProperty $RegPath "AutoLogonCount" -Value "1" -type DWord

	Write-Host End of Set autologon

	#Set next script to run on next logon
	Write-Host "Setting $NextScript to start on next logon"
	Set-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'InstallAgent' -Value "PowerShell.exe -WindowStyle Maximized -NoLogo -NoExit -ExecutionPolicy Bypass -File `"C:\IT\$NextScript`""
}
