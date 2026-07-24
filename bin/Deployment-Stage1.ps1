Start-transcript -path C:\IT\deployment.log -force -append
Write-Host "Running script: $($MyInvocation.MyCommand.Name) on $(Get-Date)"

. (Join-Path $PSScriptRoot 'Deployment-Functions.ps1')

#Rename the local admin user to name specified in .env.ps1
Rename-LocalUser -Name "admin" -NewName "$DefaultUsername"
Set-LocalUser -Name "$DefaultUsername" -Password (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force)

Change-Hostname
Uninstall-McAfee
Install-Applications
Deploy-Bitlocker
Read-Host "Stage 1 complete"
Set-AutoLogon -NextScript "Deployment-Stage2.ps1"
Restart-Computer
