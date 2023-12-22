---
author: Juan Garrido
---

Monkey365 supports many options to help customize and automate scans. General options include:

```-Environment```

It can be used to set the environment containing the Azure account. Valid values are:

* AzureChina
* AzureGermany
* AzurePublic
* AzureUSGovernment

**Note**: Default value is ```AzurePublic```

 ```-Instance```

Specifies the cloud provider to use. Valid values are:

* Azure
* Microsoft365

 ```-TenantID```

It can be used to force Monkey365 to sign in to a tenant

```-IncludeEntraID```

Use this flag to scan a Microsoft Entra ID tenant:

``` powershell

$param = @{
    Instance = 'Microsoft365';
    Analysis = 'ExchangeOnline';
    PromptBehavior = 'SelectAccount';
	IncludeEntraID = $true;
    ExportTo = 'HTML';
}
Invoke-Monkey365 @param
```

```-SaveProject```

Saves project to a local folder (Default folder is monkey-reports)

```-Compress```

This flag will compress all the output data into a single zip file (Default folder is monkey-reports\GUID\zip)

``` powershell

Invoke-Monkey365 -Instance Microsoft365 -Analysis ExchangeOnline -ExportTo HTML -Compress

```

```-ImportJob```

Import previously exported jobs

```-PromptBehavior```

Sets the behavior for authentication. Valid values are ```ForceLogin```, ```Never```, ```NoPrompt``` and ```SelectAccount```

```-ForceAuth```

Force the prompt behavior and user will be prompted for credentials. <br /> Same as ```-PromptBehavior ForceLogin```

```-ForceMSALDesktop```

force PowerShell 6 and higher to load .NET MSAL libraries instead of .NET core versions. <span style="color:red">*Only valid on Windows environments*</span>

```-RuleSet```

Specifies the path to JSON rules file.

```-ExcludeCollector```

This option can be used to exclude collectors from being executed. For example, there are situations when you may need to exclude an specific collector, for example in tenants with thousands of users/mailboxed, that would slow down the scan.

``` powershell
$param = @{
    Instance = 'Microsoft365';
    Analysis = 'ExchangeOnline';
    PromptBehavior = 'SelectAccount';
    TenantID = '00000000-0000-0000-0000-000000000000';
	ExcludeCollector = exo0003, exo0004, exo0005;
    ExportTo = 'HTML';
}
Invoke-Monkey365 @param
```