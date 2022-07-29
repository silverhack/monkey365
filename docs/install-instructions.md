---
author: Juan Garrido
---

This section covers the process of installing Monkey365 module from GitHub using PowerShell.

## Operating System Support

The Monkey365 codebase was upgraded to support PowerShell Core and MSAL, which is the new authentication platform library for both Azure and Microsoft 365. These new features make the code OS independent. It has been tested on Windows, Linux (Ubuntu, Debian), as well as on Ubuntu-On-Windows.

The following platforms are supported:

* Windows PowerShell 5.1 with .NET Framework 4.7.2 or greater
* PowerShell 7.1 or greater on Linux and Windows

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
You can download the latest zip by clicking [here](https://github.com/silverhack/monkey365/archive/refs/heads/main.zip). Once downloaded, you must extract the file and extract the files to a suitable directory.

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