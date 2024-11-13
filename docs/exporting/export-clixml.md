---
author: Juan Garrido
---


## Export To CLIXML

The `-ExportTo CLIXML` will serialize an XML-based representation of report and will store it in a file.

``` PowerShell
$p = @{
    Instance = 'Azure';
    Collect = 'All';
    PromptBehavior = 'SelectAccount';
    AllSubscriptions = $true;
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'CLIXML';
}
Invoke-Monkey365 @p
```

## CLIXML Properties

Properties will be the same as [JSON](../export-json) output.