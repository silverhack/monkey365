---
author: Juan Garrido
---

This section covers the supported options to help customize and automate scans for Microsoft 365 environments. General options include:

 ```--Collect```

Select the Microsoft 365 resources used to gather data. Valid values are:

| Resource        | Value         |
| --------------- |:-------------|
| ExchangeOnline | Gather configuration data from Exchange Online, including detailed settings for mailboxes, mail flow connectors (inbound and outbound), and transport infrastructure components, among other relevant components |
| SharePointOnline | Retrieve metadata and configuration details from SharePoint Online, including site collections, lists and libraries, user and group memberships, as well as identification of orphaned or inactive user accounts, among other relevant components|
| Purview | Fetch information from Microsoft Purview |
| MicrosoftTeams | Collect configuration and policy details from Microsoft Teams, including app permission policies, app setup policies, guest access and calling settings, among other operational components.|
| AdminPortal | Fetch basic information from Microsoft 365 admin portal |

Currently, you can use tab completion in Monkey365 to complete `Collect`, `Instance` and `PromptBehavior` names. You can autocomplete by pressing the `[TAB]` and the option will fill in. If more than one option is available, you can press `[TAB]` twice to display the next possible choice.

## SharePoint Online

The `-ScanSites` option allows you to specify one or more SharePoint URLs manually. This parameter is particularly helpful when Monkey365 cannot automatically detect the root SharePoint URL.

```PowerShell

$param = @{
    Instance = 'Microsoft365';
    Collect = 'ExchangeOnline','MicrosoftTeams','Purview','SharePointOnline';
    PromptBehavior = 'SelectAccount';
    IncludeEntraID = $true;
    ExportTo = 'HTML';
    ScanSites = "https://your-domain.sharepoint.com";
}
Invoke-Monkey365 @param
```