*Faster than Deployment Classic. Less pain than Deployment 1.5*

# Deployment2

Automated deployment scripts and provisioning without imaging for Windows systems. Includes multi-stage installation workflows, agent deployment (ConnectWise Automate), and OS configuration via PowerShell and provisioning packages.

## Getting Started

1. Copy the deployment2 repository to the root of a Windows partitioned drive (e.g. D:\)
2. Copy examples/example.env.ps1 to bin/.env.ps1 updated with your credentials.
3. Plug drive into a new windows workstation running Windows 11 at OOBE.
    - If not automattically detected hit the windows key 5 times and select "Install Provising Package" from the menu that follows

## Troubleshooting

A log file is generated on C:\IT\deployment.log
