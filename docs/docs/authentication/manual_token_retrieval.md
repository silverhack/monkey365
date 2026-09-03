---
author: Juan Garrido
---

# Manual Token Retrieval

In cases where users cannot request or obtain the required Microsoft Graph permissions for the Microsoft's tenant‑owned Microsoft Graph Client ID, users could authenticate directly through their own browser session and then manually extract the resulting tokens tied to Microsoft Graph for use within Monkey365. It is intended solely for cases where the standard Microsoft Graph client ID cannot be used and no automated authorization flow is available. The video below demonstrates the manual steps involved in retrieving this token.

<video controls src="https://github.com/user-attachments/assets/01996399-56f7-43c9-89c4-54118fcb1551">

https://github.com/user-attachments/assets/01996399-56f7-43c9-89c4-54118fcb1551

</video>

Once the token has been obtained, it can be passed directly to Monkey365 using the following example:

```powershell
$graph = "ey0...."

$p = @{
    AccessToken = $graph;
    IncludeEntraId = $true;
    TenantId = "00000000-0000-0000-0000-000000000000";
	ExportTo = @('HTML');
    Verbose = $true;
    InformationAction = "Continue"
}
Invoke-Monkey365 @p
```