Start-transcript -path C:\IT\deployment.log -force -append
Write-Host "Second stage initiated"

. (Join-Path $PSScriptRoot 'Deployment-Functions.ps1')

Deploy-Automate
Write-Host "Check ScreenConnect > No Session Group $(hostname)"
Write-Host "Start VPN, Domain, and user setup"
Write-Host "Updates will still need to be ran"
Write-Host "Rebooting into post-deployment"
Set-AutoLogon -NextScript "Deployment-StagePost.ps1"
Restart-Computer
