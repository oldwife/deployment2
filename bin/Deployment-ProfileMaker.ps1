#Start-transcript -path C:\IT\deployment.log -force -append
#Write-Host "Running script: $($MyInvocation.MyCommand.Name) on $(Get-Date)"


touch C:\Temp\exampleprofile.json
$ProfilePath="C:\Temp\exampleprofile.json"
$env:FZF_DEFAULT_OPTS="--layout=reverse-list --padding=10 --preview='cat $ProfilePath'" 

$list = [System.Collections.ArrayList]@()
$list.Add("Domain") | Out-Null
$list.Add("VPN") | Out-Null
$list.Add("User") | Out-Null
$list.Add("Save profile") | Out-Null
$list.Add("Import profile") | Out-Null
$list.Add(" ") | Out-Null
$list.Add("Confirm") | Out-Null

$VpnName = "Vpn Name"
$VpnType = "SSTP or IKEv2"
$Domain  = "DOMAIN"
$User  = "firstname.lastname"

function Export-Profile {
	$profile = [PSCustomObject]@{
		User	= $User
		VpnName	= $VpnName
		VpnType	= $VpnType
		Domain	= $Domain
	}
	$json = $profile | ConvertTo-Json > $ProfilePath
}

Export-Profile

function Get-VPNProfile {
	$VpnName=(echo "VPN" | fzf --prompt="Hit enter to use default" --print-query --bind 'enter:replace-query+print-query')
	$VpnType=( echo "SSTP`nIKEv2" | fzf --prompt="Select VPN type")
	Export-Profile
	Get-MainMenu
}

function Get-UserProfile {
	$User=(echo "firstname.lastname" | fzf --prompt="$Domain\" --print-query --bind 'enter:replace-query+print-query')
	Export-Profile
	Get-MainMenu
}

function Get-DomainProfile {
	$Domain=(echo "Domain" | fzf --prompt="Domain: " --print-query --bind 'enter:replace-query+print-query')
	Export-Profile
	Get-MainMenu
}

function Import-DeploymentProfile {
	$NewProfilePath=Get-ChildItem -Path D:\, C:\IT -Filter *.json -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | fzf --preview 'type {}'

	if ($NewProfilePath -and (Test-Path -Path $NewProfilePath -PathType Leaf)) {
		try {
			Get-Content -Path $NewProfilePath | ConvertFrom-Json | Out-Null
			Copy-Item -Path $NewProfilePath -Destination "C:\Temp\exampleprofile.json" -Force
			Write-Host "Profile imported successfully"
		} catch {
			Write-Host "Error: Selected file is not valid JSON. Please try again."
		}
	} elseif ($NewProfilePath) {
		Write-Host "Error: File does not exist or is not accessible."
	}

	Get-MainMenu
}

function Export-DeploymentProfile {
	$SelectedDir = Get-ChildItem -Path C:\IT, D:\ -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | fzf --preview 'dir {}'

	if ($SelectedDir -and (Test-Path -Path $SelectedDir -PathType Container)) {
		$DateStamp = (Get-Date -Format "yyMMdd-HHmm")
		$DefaultFileName = "$DateStamp.$Domain.json"
		$FileName = (echo $DefaultFileName | fzf --prompt="Enter filename: " --print-query --bind 'enter:replace-query+print-query')

		if ($FileName) {
			$ProfilePath = Join-Path -Path $SelectedDir -ChildPath $FileName
			Write-Host "Profile will be saved to: $ProfilePath"
			Export-Profile
		} else {
			Write-Host "Export cancelled."
		}
	} else {
		Write-Host "Error: Invalid directory selected or directory does not exist."
	}
	Get-MainMenu
}

function Get-MainMenu {
	$choice=($list | fzf  --preview="cat $ProfilePath")

	switch ($choice) {
		'VPN' {
			Get-VPNProfile
		}
		'Domain' {
			Get-DomainProfile
		}
		'User' {
			Get-UserProfile
		}
		'Save profile' {
			Export-DeploymentProfile
		}
		'Import profile' {
			Import-DeploymentProfile
		}
		'Confirm' {
			Start-PostDeployment
		}
		default {
			#catchall
			Write-Host "Invalid response, try again." ; Get-MainMenu
		}
	}
}
Get-MainMenu

function Start-CleanUp {
	Write-Host "Cleaning up example profile"
	Remove-Item C:\Temp\exampleprofile.json
}
Start-CleanUp 
