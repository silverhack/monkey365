---
author: Juan Garrido
hide:
  - navigation
  - toc
---

# Monkey365

<div class="center">
<img src='assets/images/MonkeyLogo.png' />
</div>

[![GitHub release](https://img.shields.io/github/v/release/silverhack/monkey365?display_name=tag&sort=semver)](https://github.com/silverhack/monkey365/releases)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/monkey365)](https://www.powershellgallery.com/packages/monkey365/)
[![License](https://img.shields.io/github/license/silverhack/monkey365)](https://github.com/silverhack/monkey365/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/silverhack/monkey365?style=social)](https://github.com/silverhack/monkey365/stargazers)
[![Follow @tr1ana](https://img.shields.io/twitter/follow/tr1ana?style=social)](https://twitter.com/tr1ana)
[![GitHub Downloads](https://img.shields.io/github/downloads/silverhack/monkey365/total?style=flat&logo=powershell&label=GitHub%20Release%20Download)](https://github.com/silverhack/monkey365/releases)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/monkey365.svg?style=flat&logo=powershell&label=PSGallery%20Download)](https://www.powershellgallery.com/packages/monkey365)

Monkey365 is an Open Source security tool that can be used to easily conduct not only Microsoft 365, but also Azure subscriptions and Microsoft Entra ID security configuration reviews without the significant overhead of learning tool APIs or complex admin panels from the start.

Monkey365 has been designed to tackle these difficulties and get results fast and without any requirements. The results can be visualised in a simplified HTML report to quickly identify potential issues. As such, security consultants will be able to effectively address issues from a single vulnerability report. Click through findings, and evidence in a report format suitable for reviews.

![](assets/images/htmlreport.png)

To help with this effort, Monkey365 also provides several ways to identify security gaps in the desired tenant setup and configuration. Monkey365 provides valuable recommendations on how to best configure those settings to get the most out of your Microsoft 365 tenant or Azure subscription.

# Architecture

<div class="center">
<img src='assets/images/monkey365_arch.png' />
</div>

Monkey365 works in three phases. In the first phase, collectors will issue queries against the multiple data sources to retrieve the desired metadata about targeted tenant or subscription, and then will collect information. Once all the necessary metadata is collected, the result is passed to an internal module in order to start the verifying phase, in which the tool uses the data collected in first phase to perform query search with a default set of rules, as a mechanism to evaluate the configuration and to search for potential misconfigurations and security issues. The third phase starts to generate reports, such as an HTML report containing structured data for quick checking and verification of the results.

# Getting Started

```powershell
#Install module
Install-Module Monkey365 -Scope CurrentUser
#Set params
$param = @{
    Instance = 'Microsoft365';
    Collect = 'ExchangeOnline','MicrosoftTeams','Purview','SharePointOnline';
    PromptBehavior = 'SelectAccount';
    IncludeEntraID = $true;
    ExportTo = 'HTML';
}
#Execute monkey365
Invoke-Monkey365 @param
```

---

[Getting started](install/install-instructions.md){ .md-button .md-button--primary }
[Quick start](getting_started/basic-usage.md){ .md-button }
[Authentication](authentication/overview.md){ .md-button }
[Sample report](sample/monkey365_azure.html){ .md-button }

!!! warning "Permissions required"
    Monkey365 needs appropriate permissions to read tenant and subscription configuration data.  
    Review: [Required permissions →](getting_started/permissions.md)

---

# Automation-friendly output

Export results as **JSON**, **CSV**, or **CLIXML** for pipelines and post-processing.

- [Exporting overview](exporting/exporting-data.md)
- [Export JSON](exporting/export-json.md)
- [Export CSV](exporting/export-csv.md)
- [Export HTML](exporting/export-html.md)

# Extensible security checks
Create custom rules and rulesets for organization-specific controls.

- [Security checks overview](security_checks/overview.md)
- [Create a custom rule](security_checks/custom-rule.md)
- [Custom ruleset](security_checks/custom-ruleset.md)

# Next steps

- Configure scan behavior → [General options](configuration/general-options.md)
- Azure-specific tuning → [Azure options](configuration/azure-options.md)
- Microsoft 365 tuning → [Microsoft 365 options](configuration/microsoft365-options.md)
- Handle throttling → [Rate limits & retry](configuration/rate-limit.md)
- Logging (File/Slack/Teams) → [Logging introduction](logging/introduction.md)