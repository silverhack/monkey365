<p align="center">
  <img src="https://user-images.githubusercontent.com/5271640/181045413-1d17333c-0533-404a-91be-2070ccc6ee29.png" width="240" alt="Monkey365 logo"/>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/silverhack/monkey365"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365"><img src="https://img.shields.io/powershellgallery/v/monkey365" alt="PowerShell Gallery version"></a>
  <a href="https://github.com/silverhack/monkey365/actions/workflows/pester.yml"><img src="https://github.com/silverhack/monkey365/actions/workflows/pester.yml/badge.svg" alt="Pester tests"></a>
  <a href="https://github.com/silverhack/monkey365/actions/workflows/psscriptanalyzer.yml"><img src="https://github.com/silverhack/monkey365/actions/workflows/psscriptanalyzer.yml/badge.svg" alt="PSScriptAnalyzer"></a>
  <a href="https://app.codacy.com/gh/silverhack/monkey365/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade"><img src="https://app.codacy.com/project/badge/Grade/f1633c7261f74232931a59b2adee7ec7"/></a>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/issues"><img alt="Issues" src="https://img.shields.io/github/issues/silverhack/monkey365"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/silverhack/monkey365" alt="Apache 2.0 license"></a>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/releases"><img src="https://img.shields.io/github/downloads/silverhack/monkey365/total?logo=powershell&label=GitHub%20downloads" alt="GitHub downloads"></a>
  <a href="https://www.powershellgallery.com/packages/monkey365"><img src="https://img.shields.io/powershellgallery/dt/monkey365.svg?logo=powershell&label=PowerShell%20Gallery%20downloads" alt="PowerShell Gallery downloads"></a>
</p>

<p align="center">
  <a href="https://github.com/silverhack/monkey365/stargazers"><img src="https://img.shields.io/github/stars/silverhack/monkey365?style=social" alt="Stars"></a>
  <a href="https://twitter.com/tr1ana"><img src="https://img.shields.io/twitter/follow/tr1ana?style=social" alt="Follow @tr1ana"></a>
</p>

# Monkey365

Monkey365 is a PowerShell-based security assessment framework for Microsoft 365, Microsoft Entra ID, and Azure. It collects configuration data, evaluates it against security rules, and produces reports with the evidence and remediation guidance needed to review each finding.

The module is self-contained: its runtime dependencies are bundled, so it does not require the Azure CLI, Az PowerShell, ExchangeOnlineManagement, or the Microsoft Graph PowerShell SDK.

It helps security professionals, consultants, administrators, and incident responders identify misconfigurations, review cloud security posture, and evaluate environments against industry security best practices and compliance standards.

Monkey365 simplifies Microsoft cloud security assessments without requiring users to learn complex APIs, install multiple Microsoft modules, or navigate multiple administration portals.


## Features

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
  - Service principals
  - Certificate-based authentication
  - Direct access token authentication
- Declarative security rules and rulesets configured with JSON files
- Structured HTML, JSON, and CSV reporting for automation and analysis workflows
- Support for Azure Public, China, and Government cloud environments
- Collector-based and extensible architecture
- Easy deployment across workstations, jump boxes, automation pipelines, and assessment environments

## Quick start

Install Monkey365 from the PowerShell Gallery:

```powershell
Install-Module -Name monkey365 -Scope CurrentUser
Import-Module monkey365
```

Run a Microsoft 365 assessment and include Microsoft Entra ID:

```powershell
$options = @{
    Instance       = 'Microsoft365'
    Collect        = @(
        'ExchangeOnline'
        'MicrosoftTeams'
        'SharePointOnline'
    )
    PromptBehavior = 'SelectAccount'
    IncludeEntraID = $true
    ExportTo       = 'HTML'
}

Invoke-Monkey365 @options
```

Monkey365 prompts you to sign in when the selected authentication flow requires
it. The services available to the scan depend on the permissions granted to the
signed-in identity.

Before scanning a production environment, review the
[installation guide](https://silverhack.github.io/monkey365/install/install-instructions/),
[required permissions](https://silverhack.github.io/monkey365/getting_started/permissions/),
and [authentication options](https://silverhack.github.io/monkey365/authentication/overview/).

## How it works

Monkey365 separates an assessment into three stages:

1. **Collect** configuration data from the selected cloud services.
2. **Evaluate** the collected data with the selected rulesets.
3. **Report** findings, supporting evidence, and remediation guidance.

Security rules are declarative and configured in JSON files. They are evaluated
separately from collectors, so you can add organization-specific checks without
changing the scan engine. Review the [bundled rules](https://github.com/silverhack/monkey365/tree/main/rules)
or see [Custom checks and rulesets](https://silverhack.github.io/monkey365/security_checks/overview/)
for the configuration model.

## Reports and automation

Use `-ExportTo` to select one or more output formats:

| Format | Best suited for |
| --- | --- |
| `HTML` | Interactive review of findings and evidence |
| `JSON` | Pipelines, APIs, and structured post-processing |
| `CSV` | Spreadsheet analysis and data exchange |

<p align="center">
  <img src="docs/docs/assets/images/htmlreport.png" alt="Example Monkey365 HTML report">
</p>

The documentation includes details for
[exporting results](https://silverhack.github.io/monkey365/exporting/exporting-data/),
[rate limits and retries](https://silverhack.github.io/monkey365/configuration/rate-limit/),
and [logging](https://silverhack.github.io/monkey365/logging/introduction/).

## Rulesets

The bundled rulesets currently include:

- CIS Microsoft Azure Foundations Benchmark v6.0.0
- CIS Microsoft Azure Database Services Benchmark v2.0.0
- CIS Microsoft Azure Compute Services Benchmark v2.0.0
- CIS Microsoft 365 Foundations Benchmark v7.0.0
- Monkey365 Microsoft Entra ID ruleset

A benchmark mapping identifies the control associated with a finding; it does
not by itself establish certification or compliance. Review each result in the
context of the assessed environment and its licensing, business, and risk
requirements.

## Authentication and permissions

Monkey365 supports both delegated and application authentication. Support
varies by workload—for example, some Microsoft 365 services require a
certificate rather than a client secret for app-only access. Use the
[authentication support matrix](https://silverhack.github.io/monkey365/authentication/supported_auth_methods_byapp/)
before choosing an unattended authentication flow.

Monkey365 is designed to read configuration data and does not remediate or
modify cloud resources. Use least-privilege roles and API permissions, protect
assessment output as sensitive data, and remove tenant identifiers and secrets
before sharing logs or reports.

## Documentation

| Topic | Link |
| --- | --- |
| Install Monkey365 | [Installation guide](https://silverhack.github.io/monkey365/install/install-instructions/) |
| Run a scan | [Basic usage](https://silverhack.github.io/monkey365/getting_started/basic-usage/) |
| Configure a scan | [General options](https://silverhack.github.io/monkey365/configuration/general-options/) |
| Choose an authentication flow | [Authentication overview](https://silverhack.github.io/monkey365/authentication/overview/) |
| Grant access | [Required permissions](https://silverhack.github.io/monkey365/getting_started/permissions/) |
| Run in a container | [Docker guide](https://silverhack.github.io/monkey365/docker/docker/) |
| Write custom checks | [Security checks](https://silverhack.github.io/monkey365/security_checks/overview/) |

For command syntax and examples, use PowerShell's built-in help:

```powershell
Get-Help Invoke-Monkey365 -Detailed
Get-Help Invoke-Monkey365 -Examples
```

## Contributing and support

Contributions to code, tests, documentation, collectors, and security checks are
welcome. Read [CONTRIBUTING.md](.github/CONTRIBUTING.md) before opening a pull request
and follow the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

- Ask usage questions in [GitHub Discussions](https://github.com/silverhack/monkey365/discussions).
- Report reproducible bugs through [GitHub Issues](https://github.com/silverhack/monkey365/issues).
- Follow [SECURITY.md](SECURITY.md) to report a vulnerability privately.
- See [SUPPORT.md](SUPPORT.md) for the project's support policy.

Do not post credentials, tokens, tenant data, or unredacted assessment reports
in a public issue or discussion.

## License

Monkey365 is licensed under the [Apache License 2.0](LICENSE).
