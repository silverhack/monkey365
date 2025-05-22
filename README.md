<p align="center">
  <img src="https://user-images.githubusercontent.com/5271640/181045413-1d17333c-0533-404a-91be-2070ccc6ee29.png" width="45%" height="45%" />
</p>
<p align="center">
  <a href="https://github.com/silverhack/monkey365"><img alt="License" src="https://img.shields.io/github/license/silverhack/monkey365"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="Pester" src="https://github.com/silverhack/monkey365/actions/workflows/pester.yml/badge.svg"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="ScriptAnalyzer" src="https://github.com/silverhack/monkey365/actions/workflows/scriptanalyzer.yml/badge.svg"></a>
  <a href="https://github.com/silverhack/monkey365"><img alt="Lines" src="https://img.shields.io/tokei/lines/github/silverhack/monkey365"></a>
  <a href="https://twitter.com/tr1ana"><img alt="Twitter" src="https://img.shields.io/twitter/follow/tr1ana?style=social"></a>
  <a href="https://github.com/silverhack/monkey365/releases"><img alt="GitHub Downloads" src="https://img.shields.io/github/downloads/silverhack/monkey365/total"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365"><img alt="PowerShell Gallery" src="https://img.shields.io/powershellgallery/v/monkey365.svg?label=latest+version"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365"><img alt="PowerShell Gallery Downloads" src="https://img.shields.io/powershellgallery/dt/monkey365.svg?label=downloads"></a>
</p>

<p
  <i>Monkey365</i> is an Open Source security tool that can be used to easily conduct not only Microsoft 365, but also Azure subscriptions and Microsoft Entra ID security configuration reviews without the significant overhead of learning tool APIs or complex admin panels from the start. To help with this effort, Monkey365 also provides several ways to identify security gaps in the desired tenant setup and configuration. Monkey365 provides valuable recommendations on how to best configure those settings to get the most out of your Microsoft 365 tenant or Azure subscription.
</p>

# Introduction

Monkey365 is a collector-based PowerShell module that can be used to review the security posture of your cloud environment. With Monkey365 you can scan for potential misconfigurations and security issues in public cloud accounts according to security best practices and compliance standards, across Azure, Microsoft Entra ID, and Microsoft 365 core applications.

# Installation

## PowerShell Gallery

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

## GitHub

You can download the latest release by clicking [here](https://github.com/silverhack/monkey365/releases). Once downloaded, you must extract the file and extract the files to a suitable directory.

Once downloaded, you must extract the files to a suitable directory. Once you have unzipped the zip file, you can use the PowerShell V3 Unblock-File cmdlet to unblock files:

``` powershell
Get-ChildItem -Recurse c:\monkey365 | Unblock-File
```

Once you have installed the monkey365 module on your system, you will likely want to import the module with the Import-Module cmdlet. Assuming that Monkey365 is located in the ```PSModulePath```, PowerShell would load monkey365 into active memory:
``` powershell
Import-Module monkey365
```
If Monkey365 is not located on a ```PSModulePath``` path, you can use an explicit path to import:
``` powershell
Import-Module C:\temp\monkey365
```
You can also use the ```Force``` parameter in case you want to reimport the Monkey365 module into the same session
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
$options = @{
    Instance = 'Microsoft365';
    Collect = 'ExchangeOnline';
    PromptBehavior = 'SelectAccount';
    IncludeEntraID = $true;
    ExportTo = 'CSV';
}
Invoke-Monkey365 @options
```

# Regulatory compliance checks

Monkey365 helps streamline the process of performing not only Microsoft 365, but also Azure subscriptions and Azure Active Directory Security Reviews.

160+ checks covering industry defined security best practices for Microsoft 365, Azure and Azure Active Directory. 

Monkey365 will help consultants to assess cloud environment and to analyze the risk factors according to controls and best practices. The report will contain structured data for quick checking and verification of the results.

<p align="center">
  <img src="https://silverhack.github.io/monkey365/assets/images/htmlreport.png" />
</p>

# Supported standards

By default, the HTML report shows you the CIS (Center for Internet Security) Benchmark. The CIS Benchmarks for Azure and Microsoft 365 are guidelines for security and compliance best practices.

The following standards are supported by Monkey365:

* CIS Microsoft Azure Foundations Benchmark v3.0.0
* CIS Microsoft 365 Foundations Benchmark v3.0.0 and v4.0.0

More standards will be added in next releases (NIST, HIPAA, GDPR, PCI-DSS, etc..) as they are available.

Additional information such as Installation or advanced usage can be found in the following [link](https://silverhack.github.io/monkey365/)

# Star History

[![Star History Chart](https://api.star-history.com/svg?repos=silverhack/monkey365&type=Date)](https://www.star-history.com/#silverhack/monkey365&Date)
