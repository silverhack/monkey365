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
