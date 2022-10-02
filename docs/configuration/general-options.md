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
* Office365

 ```-TenantID```

It can be used to force Monkey365 to sign in to a tenant

```-ResolveTenantDomainName```

It can be used to resolve the unique ID of the tenant name

```-ResolveTenantUserName```

It can be used to resolve the Tenant ID for a specific user

```-IncludeAzureActiveDirectory```

It can be used to get information from Azure Active Directory

```-SaveProject```

Saves project to a local folder (Default folder is monkey-reports)

```-ImportJob```

Import previously exported jobs

```-PromptBehavior```

Sets the behavior for authentication. Valid values are ```Always```, ```Auto```, ```Never```, ```RefreshSession``` and ```SelectAccount```

```-ForceAuth```

Force the prompt behavior and user will be prompted for credentials. <br /> Same as ```-PromptBehavior Always```

```-RuleSet```

Specifies the path to JSON rules file.

```-ExcludePlugin```
This option can be used to exclude plugins from being executed. For example, there are situations when you may need to exclude an specific plugin, for example in tenants with thousands of users/mailboxed, that would slow down the scan.

``` powershell
$param = @{
    Instance = 'Microsoft365';
    Analysis = 'ExchangeOnline';
    PromptBehavior = 'SelectAccount';
    TenantID = '00000000-0000-0000-0000-000000000000';
	ExcludePlugin = exo0003, exo0004, exo0005;
    ExportTo = 'HTML';
}
Invoke-Monkey365 @param
```