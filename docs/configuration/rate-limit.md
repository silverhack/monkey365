---
author: Juan Garrido
---

The Monkey365 tool runs with 2 threads by default. Additionally, Monkey365 handles rate limiting by implementing a ```MaxQueue``` value that configures the number of worker threads that are available for the tool. When the tool detects that the ```MaxQueue``` limit is reached, the ```Start-Sleep``` command will be used to delay requests for a fixed amount of time. This is often sufficient to complete a run.

In addition to the default execution, the ```Threads``` option can be used to modify the default behavior.

The following example will fetch data from specific Azure subscription and Tenant and then will export results to CSV. If credentials are not supplied, Monkey365 will prompt for credentials. In addition, the ```Threads``` flag is set to ```4```.

``` powershell
$param = @{
    Instance = 'Azure';
    Analysis = 'All';
    PromptBehavior = 'SelectAccount';
    subscriptions = '00000000-0000-0000-0000-000000000000';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'CSV';
    Threads = 4;
}
$assets = Invoke-Monkey365 @param
```

Regarding Exchange Online, and since the maximum number of remote connections allowed is 5, Monkey365 will limit the remote connections to one open remote PowerShell connection, regardless of number of configured threads. This is often enough to complete all jobs.

For information regarding connecting Exchange Online, please refer to the installation notes on Microsoft:

<a href='https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps' target='_blank'>Connect to Exchange Online PowerShell</a>