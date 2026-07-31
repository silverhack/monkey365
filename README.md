<p align="center">
  <img src="https://user-images.githubusercontent.com/5271640/181045413-1d17333c-0533-404a-91be-2070ccc6ee29.png" width="300" height="300" />
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/releases"><img src="https://img.shields.io/github/v/release/silverhack/monkey365?display_name=tag&sort=semver" alt="GitHub release"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365/"><img src="https://img.shields.io/powershellgallery/v/monkey365" alt="PowerShell Gallery"></a>
  <a href="https://github.com/silverhack/monkey365/stargazers"><img src="https://img.shields.io/github/stars/silverhack/monkey365?style=social" alt="Stars"></a>
  <a href="https://twitter.com/tr1ana"><img src="https://img.shields.io/twitter/follow/tr1ana?style=social" alt="Follow @tr1ana"></a>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/issues"><img alt="Issues" src="https://img.shields.io/github/issues/silverhack/monkey365"></a>
  <a href="https://github.com/silverhack/monkey365/blob/main/LICENSE"><img src="https://img.shields.io/github/license/silverhack/monkey365" alt="License"></a>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/releases"><img src="https://img.shields.io/github/downloads/silverhack/monkey365/total?style=flat&logo=powershell&label=GitHub%20Release%20Download" alt="GitHub Downloads"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365"><img src="https://img.shields.io/powershellgallery/dt/monkey365.svg?style=flat&logo=powershell&label=PSGallery%20Download" alt="PowerShell Gallery Downloads"></a>
</p>

Monkey365 is an open-source security assessment framework for Microsoft 365, Azure, and Microsoft Entra ID. It helps security professionals, consultants, administrators, and incident responders identify misconfigurations, review cloud security posture, and evaluate environments against industry security best practices and compliance standards.

Monkey365 simplifies Microsoft cloud security assessments without requiring users to learn complex APIs, install multiple Microsoft modules, or navigate multiple administration portals.

---

# Features

- Self-contained PowerShell module with bundled dependencies
- No dependency on external Microsoft modules or tools, including ExchangeOnlineManagement, Az PowerShell / Azure CLI, or the Microsoft Graph PowerShell SDK
- Security posture assessment for:
  - Microsoft 365
  - Azure
  - Microsoft Entra ID
- Coverage for major Microsoft 365 workloads including:
  - Exchange Online
  - SharePoint Online
  - Microsoft Teams
  - Microsoft Purview
  - Microsoft Fabric
- Supports multiple authentication methods including:
  - Interactive authentication
  - MFA-enabled authentication
  - Service principals
  - Certificate-based authentication
  - Direct access token authentication
- CIS benchmark and compliance checks
- Structured HTML, JSON, and CSV reporting for automation and analysis workflows
- Support for Azure Public, China, and Government cloud environments
- Collector-based and extensible architecture
- Easy deployment across workstations, jump boxes, automation pipelines, and assessment environments

---

# Get Started

Install the Monkey365 PowerShell module and start assessing your environment.

[Zero configuration](https://silverhack.github.io/monkey365/install/install-instructions/) and no external Microsoft modules are required.

```powershell
Install-Module -Name monkey365 -Scope CurrentUser
Import-Module monkey365

$options = @{
    Instance        = 'Microsoft365'
    Collect         = @('ExchangeOnline', 'SharePointOnline')
    PromptBehavior  = 'SelectAccount'
    IncludeEntraID  = $true
    ExportTo        = 'HTML'
}

Invoke-Monkey365 @options
```

> [!NOTE]
> Monkey365 includes bundled dependencies and does not require additional Microsoft PowerShell modules.

---

# Introduction

Monkey365 is a collector-based PowerShell security assessment framework distributed as a self-contained module that helps assess the security posture of cloud environments. It scans Microsoft 365, Azure, and Microsoft Entra ID for potential security issues, configuration weaknesses, and deviations from security best practices.

The framework provides recommendations to help organizations strengthen cloud security posture and improve compliance readiness.

---

# Authentication

Monkey365 supports multiple authentication methods for both interactive and automated assessments.

Supported authentication workflows include:

- Interactive authentication
- MFA-enabled authentication
- Service principals
- Certificate-based authentication
- Direct access token authentication

Authentication documentation:

- Authentication overview  
  https://silverhack.github.io/monkey365/authentication/overview/

- Access token authentication  
  https://silverhack.github.io/monkey365/authentication/access_token/

---

# Basic Usage

Display available command options:

```powershell
Get-Help Invoke-Monkey365
```

Display usage examples:

```powershell
Get-Help Invoke-Monkey365 -Examples
```

Display detailed help information:

```powershell
Get-Help Invoke-Monkey365 -Detailed
```

Example assessment:

```powershell
$options = @{
    Instance        = 'Microsoft365'
    Collect         = @('ExchangeOnline','MicrosoftFabric','MicrosoftTeams','SharePointOnline')
    PromptBehavior  = 'SelectAccount'
    IncludeEntraID  = $true
    ExportTo        = 'HTML'
}

Invoke-Monkey365 @options
```

If credentials are not supplied, Monkey365 prompts for authentication.

---

# Running Monkey365 in National or Government Cloud Environments

Use the `-Environment` parameter with `Invoke-Monkey365` to specify the target cloud environment.

Supported environments:

- `AzurePublic` (default)
- `AzureChina`
- `AzureUSGovernment`

Example:

```powershell
$options = @{
    Environment     = 'AzureUSGovernment'
    Instance        = 'Microsoft365'
    Collect         = @('ExchangeOnline', 'SharePointOnline')
    PromptBehavior  = 'SelectAccount'
    IncludeEntraID  = $true
    ExportTo        = @('JSON', 'HTML')
}

Invoke-Monkey365 @options
```

---

# Regulatory Compliance Checks

Monkey365 includes hundreds of built-in checks aligned with industry security best practices and compliance frameworks for Microsoft cloud environments.

The framework helps organizations:

- Identify security gaps
- Review cloud configuration posture
- Validate tenant hardening
- Analyze identity and access controls
- Assess compliance readiness

Assessment reports include structured findings and remediation guidance for rapid analysis and verification.

<p align="center">
  <img src="https://silverhack.github.io/monkey365/assets/images/htmlreport.png" />
</p>

---

# Supported Standards

By default, the HTML report displays CIS (Center for Internet Security) benchmark mappings for Microsoft Azure and Microsoft 365 environments.

Currently supported standards include:

- CIS Microsoft Azure Foundations Benchmark v6.0.0
- CIS Microsoft Azure Database Services Benchmark v2.0.0
- CIS Microsoft Azure Compute Services Benchmark v2.0.0
- CIS Microsoft 365 Foundations Benchmark v7.0.0

Additional standards and frameworks may be added in future releases, including:

- NIST
- HIPAA
- GDPR
- PCI-DSS

---

# Documentation

Detailed installation guides, advanced usage examples, configuration references, and additional documentation are available at:

https://silverhack.github.io/monkey365/

---

> [!TIP]
> **Give us a Star!** If you find Monkey365 useful, please consider starring the repository on GitHub. It helps improve visibility and supports ongoing development.

---

# Star History

<a href="https://www.star-history.com/?repos=silverhack%2Fmonkey365&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=silverhack/monkey365&type=date&theme=dark&legend=top-left&sealed_token=AMLq3w8HQ4zphU_FsNWXLYVt_8wZLFcQRolk9Y8T2hdTMDCUuDjv0-jXyw48xcblVOdJGcMBN341fLnzAygwsphuit2XXFd67DimfcwDlCLzG0f_UOKbLpZEft0LJq3l0fTEgBtDApz591EZFngaot_5_R2TcX8dBSTtSUgMtStBEBYZPpfSZRR7VX4X" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=silverhack/monkey365&type=date&legend=top-left&sealed_token=AMLq3w8HQ4zphU_FsNWXLYVt_8wZLFcQRolk9Y8T2hdTMDCUuDjv0-jXyw48xcblVOdJGcMBN341fLnzAygwsphuit2XXFd67DimfcwDlCLzG0f_UOKbLpZEft0LJq3l0fTEgBtDApz591EZFngaot_5_R2TcX8dBSTtSUgMtStBEBYZPpfSZRR7VX4X" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=silverhack/monkey365&type=date&legend=top-left&sealed_token=AMLq3w8HQ4zphU_FsNWXLYVt_8wZLFcQRolk9Y8T2hdTMDCUuDjv0-jXyw48xcblVOdJGcMBN341fLnzAygwsphuit2XXFd67DimfcwDlCLzG0f_UOKbLpZEft0LJq3l0fTEgBtDApz591EZFngaot_5_R2TcX8dBSTtSUgMtStBEBYZPpfSZRR7VX4X" />
 </picture>
</a>
