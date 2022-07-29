---
author: Juan Garrido
---

This section covers the supported options to help customize and automate scans for Azure environments. General options include:

 ```--Analysis```

Select the Azure resources used to gather data. Valid values are:

| Resource        | Value         |
| --------------- |:-------------|
| Databases       | Retrieves information from Azure databases, such as Azure SQL, Azure PostgreSQL or MariaDB |
| virtualmachines | Retrieves information from Azure virtual machines |
| SecurityAlerts | Retrieves information from security alers      |
| StorageAccounts | Retrieves information from storage accounts      |
| SecurityBaseline | Retrieves information from virtual machine's security baseline      |
| MissingPatches | Retrieves information from potentially virtual machine's missing patches      |
| SecurityPolicies | Retrieves information from security policy      |
| AppServices | Retrieves information from App Services      |
| KeyVaults | Retrieves information from Azure KeyVaults      |
| roleassignments | Retrieves information from Azure RBAC      |
| SecurityContacts | Retrieves information from Security Contacts      |
| All | Retrieves all metadata from Azure subscription      |

## Subscriptions

By default, Monkey365 will show the subscriptions to which the provided identity have access to. A user can select all the subscriptions to which the provided identity have access.

![](../assets/images/subscription.png)


The ```-subscriptions``` option can be used to scan a number of subscriptions in one execution.

``` powershell
$param = @{
    Instance = 'Azure';
    Analysis = 'All';
    PromptBehavior = 'SelectAccount';
    subscriptions = '00000000-0000-0000-0000-000000000000 11111111-1111-1111-1111-111111111111';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param
```

The ```-all_subscriptions``` option can be used to scan all the subscriptions.

``` powershell
$param = @{
    Instance = 'Azure';
    Analysis = 'All';
    PromptBehavior = 'SelectAccount';
    all_subscriptions = $true;
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param
```
