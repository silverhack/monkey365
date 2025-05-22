---
author: Juan Garrido
---

This section covers the process of installing Monkey365 PowerShell module.

## Operating System Support

Monkey365 is a cross-platform module that runs on Windows, Linux, and potentially any other system that supports PowerShell. It is tested and compatible with:

* Windows PowerShell 3.0 - 5.1
* PowerShell 6.0.4 and above

## Prerequisites

Monkey365 works out of the box with PowerShell. You can check your PowerShell version executing the command ```$PsVersionTable```

```PowerShell
PS C:\Users\monkeyuser> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      7.2.4
PSEdition                      Core
GitCommitId                    7.2.4
OS                             Microsoft Windows 10.0.19044
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

### Install PowerShell on non-Windows platforms

PowerShell 7.x can be installed on macOS, Linux, and Windows but is not installed by default. For installation on non-Windows systems (i.e., Linux or macOS) please refer to the installation notes on Microsoft:

<a href='https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7' target='_blank'>Get PowerShell</a>

## Install Monkey365

### Installing from PowerShell Gallery

You can install Monkey365 using the built-in `Install-Module` command. The examples below will install Monkey365 in your  <a href="https://learn.microsoft.com/en-us/powershell/module/powershellget/install-module?view=powershellget-3.x#-scope" target="_blank">installation scope</a> depending on your PowerShell version. You can control this using the `-Scope <AllUsers/CurrentUser>` parameter.

``` powershell
Install-Module -Name monkey365 -Scope CurrentUser
```

To install a beta version, you can use the following command:

``` powershell
Install-Module -Name monkey365 -Scope CurrentUser -AllowPrerelease
```

To update monkey365:

``` powershell
Update-Module -Name monkey365 -Scope CurrentUser
```

???+ warning
	If you receive the following warning when trying to install monkey365, you may need to explicitly enable TLS 1.2.
	``` powershell
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
	Install-Module -Name monkey365 -Scope CurrentUser
	```
### Git

``` powershell
# change path to Module directory
PS C:\Users\monkeyuser> Push-Location ~\Documents\WindowsPowerShell\Modules

# clone repository
PS C:\Users\monkeyuser\Documents\WindowsPowerShell\Modules> git clone https://github.com/silverhack/monkey365.git

# return to original location
PS C:\Users\monkeyuser\Documents\WindowsPowerShell\Modules> Pop-Location
```

### Manual
You can download the latest release by clicking [here](https://github.com/silverhack/monkey365/releases). Once downloaded, you must extract the file and extract the files to a suitable directory.

Starting with new versions of Monkey365, every release will come with both SHA256 and SHA512 checksum files. These files are uploaded for any new release so you can verify the integrity of the downloaded artifacts.

???+ note
	The following snipped can be used to check the integrity of monkey365:

	``` powershell
	$cryptography = [System.Security.Cryptography.SHA256]::Create()
	$url = "https://api.github.com/repos/silverhack/monkey365/releases/latest"
	$latest = (Invoke-WebRequest -Uri $url -UserAgent "Monkey365" -ErrorAction Ignore).Content | ConvertFrom-Json -ErrorAction Ignore
	$assetsUrl = $latest.assets.Where({$_.name -eq 'monkey365.zip'}) | Select-Object -ExpandProperty browser_download_url -ErrorAction Ignore
	$zip = Invoke-WebRequest -Uri $assetsUrl -UserAgent "Monkey365" -ErrorAction Ignore
	$array = $zip.RawContentStream.ToArray()
	[byte[]]$checksum = $cryptography.ComputeHash($array);
	$shaZip = [System.BitConverter]::ToString($checksum).Replace('-', [String]::Empty).ToLowerInvariant()
	$shaurl = $latest.assets.Where({$_.name -eq 'monkey365.zip.sha256'}) | Select-Object -ExpandProperty browser_download_url -ErrorAction Ignore
	$shaFile = Invoke-WebRequest -Uri $shaurl -UserAgent "Monkey365" -ErrorAction Ignore  
	$sr = [System.IO.StreamReader]::new($shaFile.RawContentStream);
	$Hash = $sr.ReadToEnd();
	$Hash = $Hash.Trim()
	$sr.Close();
	$sr.Dispose();If($Hash.Equals($shaZip)){
		Write-Host "Cool!"
	}
	Else{
		Write-Warning "Bad!"
	}
	```

Once you have unzipped the zip file, you can use the PowerShell V3 Unblock-File cmdlet to unblock files

``` powershell
Get-ChildItem -Recurse c:\monkey365 | Unblock-File
```
## Import module
Once you have installed the monkey365 module on your system, you will likely want to import the module with the Import-Module cmdlet. Assuming that monkey365 is located in the ```PSModulePath```, PowerShell would load monkey365 into active memory:
``` powershell
Import-Module monkey365
```
If monkey365 is not located on a ```PSModulePath``` path, you can use an explicit path to import:
``` powershell
Import-Module C:\temp\monkey365
```
You can also use the ```Force``` parameter in case you want to reimport the monkey365 module into the same session
``` powershell
Import-Module C:\temp\monkey365 -Force
```