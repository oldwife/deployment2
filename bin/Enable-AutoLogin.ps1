Start-transcript -path C:\IT\deployment.log -force -append

Copy-Item -Recurse -Force -Verbose D:\* C:\IT\

Start-Sleep -Seconds 10

. (Join-Path $PSScriptRoot '.env.ps1')

Write-Host "Set autologon"

#Registry path declaration

$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$RegROPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

#setting registry values

Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $RegPath "DefaultUsername" -Value $DefaultUsername -type String
Set-ItemProperty $RegPath "DefaultPassword" -Value $DefaultPassword -type String
Set-ItemProperty $RegPath "AutoLogonCount" -Value "10" -type DWord

Write-Host "End of Set autologon"
Write-Host "Skip OOBE"

Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "SkipMachineOOBE" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "LaunchUserOOBE" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE" /v "DisablePrivacyExperience" /t REG_DWORD /d "1" /f
Set-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'InstallAgent' -Value 'PowerShell.exe -ExecutionPolicy Bypass -File "C:\IT\bin\Deployment-Stage1.ps1"' 
