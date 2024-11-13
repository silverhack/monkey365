---
author: Juan Garrido
---

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

This example retrieves information from Azure AD and SharePoint Online and then print results. If credentials are not supplied, Monkey365 will prompt for credentials.
``` powershell
$param = @{
    Instance = 'Microsoft365';
    Collect = 'SharePointOnline';
    PromptBehavior = 'SelectAccount';
    IncludeEntraID = $true;
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param
```

This example retrieves information from specific Azure subscription and Tenant and prints results to a local variable. If credentials are not supplied, Monkey365 will prompt for credentials.
``` powershell
$param = @{
    Instance = 'Azure';
    Collect = 'All';
    PromptBehavior = 'SelectAccount';
    Subscriptions = '00000000-0000-0000-0000-000000000000';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param
```

This example retrieves information from specific Azure subscription and Tenant and will export data driven to CSV, JSON, HTML, and XML format into monkey-reports folder. The script will connect to Azure using the client credential flow.
``` powershell
$param = @{
    ClientId = '00000000-0000-0000-0000-000000000000';
    ClientSecret = ("MySuperClientSecret" | ConvertTo-SecureString -AsPlainText -Force)
    Instance = 'Azure';
    Collect = 'All';
    Subscriptions = '00000000-0000-0000-0000-000000000000';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = @("CLIXML","CSV","JSON","HTML");
}
$assets = Invoke-Monkey365 @param
```

This example retrieves information from specific Azure subscription and Tenant and will export data driven to CSV, JSON, HTML, and XML format into monkey-reports folder. The script will connect to Azure using the client credential flow.
``` powershell
$param = @{
    ClientId = '00000000-0000-0000-0000-000000000000';
    certificate = 'C:\monkey365\testapp.pfx';
    CertFilePassword = ("MySuperCertSecret" | ConvertTo-SecureString -AsPlainText -Force);
    Instance = 'Microsoft365';
    Collect = 'SharePointOnline';
    Subscriptions = '00000000-0000-0000-0000-000000000000';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = @("CLIXML","CSV","JSON","HTML");
}
$assets = Invoke-Monkey365 @param
```