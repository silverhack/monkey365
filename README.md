<p align="center">
  <img src="https://user-images.githubusercontent.com/5271640/181045413-1d17333c-0533-404a-91be-2070ccc6ee29.png" width="45%" height="45%" />
</p>
<p align="center">
  <a href="https://github.com/silverhack/monkey365"><img alt="License" src="https://img.shields.io/github/license/silverhack/monkey365"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="Pester" src="https://github.com/silverhack/monkey365/actions/workflows/pester.yml/badge.svg"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="ScriptAnalyzer" src="https://github.com/silverhack/monkey365/actions/workflows/psa.yml/badge.svg"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="Lines" src="https://img.shields.io/tokei/lines/github/silverhack/monkey365"></a>
  <a href="https://twitter.com/tr1ana"><img alt="Twitter" src="https://img.shields.io/twitter/follow/tr1ana?style=social"></a>
</p>

<p align="center">
  <i>Monkey 365</i> is an Open Source security tool that can be used to easily conduct not only Microsoft 365, but also Azure subscriptions and Azure Active Directory security configuration reviews without the significant overhead of learning tool APIs or complex admin panels from the start. To help with this effort, Monkey365 also provides several ways to identify security gaps in the desired tenant setup and configuration. Monkey 365 provides valuable recommendations on how to best configure those settings to get the most out of your Microsoft 365 tenant or Azure subscription.
</p>

# Introduction

Monkey 365 is a plugin-based PowerShell module that can be used to review the security posture of your cloud environment. With Monkey 365 you can scan for potential misconfigurations and security issues in public cloud accounts according to security best practices and compliance standards, across Azure, Azure AD, and Microsoft 365 core applications.

# Installation

You can either download the latest zip by clicking [this link](https://github.com/silverhack/monkey365/archive/refs/heads/main.zip) or download Monkey 365 by cloning the [repository](https://github.com/silverhack/monkey365.git):

Once downloaded, you must extract the file and extract the files to a suitable directory. Once you have unzipped the zip file, you can use the PowerShell V3 Unblock-File cmdlet to unblock files:

``` powershell
Get-ChildItem -Recurse c:\monkey365 | Unblock-File
```

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

# Basic Usage

The following command will provide the list of available command line options:

``` powershell
Get-Help Invoke-Monkey365
```

To get a list of examples use:

``` powershell
Get-Help Invoke-Monkey365 -Examples
```

To get a list of all options and examples with detailed info use:


``` powershell
Get-Help Invoke-Monkey365 -Detailed
```

The following example will retrieve data and metadata from Azure AD and SharePoint Online and then print results. If credentials are not supplied, Monkey365 will prompt for credentials.


``` powershell
$param = @{
    Instance = 'Office365';
    Analysis = 'SharePointOnline';
    PromptBehavior = 'SelectAccount';
    IncludeAzureActiveDirectory = $true;
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param
```

Additional information such as Installation or advanced usage can be found in the following [link](https://silverhack.github.io/monkey365/)

