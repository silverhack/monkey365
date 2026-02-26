---
author: Juan Garrido
---

# Using the Microsoft Graph Client ID

Monkey365 supports multiple authentication methods when connecting to Microsoft Entra ID. By default, Monkey365 uses the **Azure PowerShell client ID** `1950a258-227b-4e31-a9cf-717495945fc2`. 

This <a href='https://learn.microsoft.com/en-us/troubleshoot/entra/entra-id/governance/verify-first-party-apps-sign-in#application-ids-of-microsoft-tenant-owned-applications' target='_blank'>client ID</a> is **pre‑authorized by Microsoft** for a **limited set of Microsoft Graph scopes**. Using the default clientId is enough for basic configuration review, but the application do **not** include many of the advanced or privileged scopes required for deeper Entra ID assessments, so there will be collectors that won't be allowed to fetch results due to lack of granted scopes. 

To support more advanced scenarios, Monkey365 also allows authentication using Microsoft's tenant‑owned Microsoft Graph Client ID `14d82eec-204b-4c2f-b7e8-296a70dab67e`

Using this client ID enables Monkey365 to request additional Microsoft Graph scopes that are **not available** through the **Azure PowerShell client ID**, such as `RoleManagement.Read.Directory` or `PrivilegedAccess.Read.AzureADGroup`. Using this clientId provides Monkey365 with broader visibility into privileged roles, access policies or directory‑wide configuration.

## Enabling Microsoft Graph Authentication

To switch from the default Azure PowerShell client ID to the Microsoft‑owned Graph Client ID, set the `useMgGraph` property to `true` in your [monkey365.config](../configuration/configuration-file.md) configuration file:

```json
"mgGraph": {
    "useMgGraph": "true"
    ...
}
```
When enabled, Monkey365 will automatically use the Microsoft Graph Client ID during authentication and request the required permissions.

## Microsoft Graph Permissions

When the Microsoft Graph Client ID is selected, Monkey365 will request the following Microsoft Graph scopes:

- User.Read.All
- Application.Read.All
- Policy.Read.All
- Organization.Read.All
- OrgSettings-AppsAndServices.Read.All
- RoleManagement.Read.Directory
- GroupMember.Read.All
- Directory.Read.All
- PrivilegedEligibilitySchedule.Read.AzureADGroup
- PrivilegedAccess.Read.AzureADGroup
- RoleManagementPolicy.Read.AzureADGroup
- Group.Read.All
- SecurityEvents.Read.All
- IdentityRiskEvent.Read.All
- UserAuthenticationMethod.Read.All
- AuditLog.Read.All
- AccessReview.Read.All

These permissions allow Monkey365 to perform a comprehensive security and configuration assessment across Entra ID, including privileged access, audit logs, identity protection, and directory‑wide configuration.

The above scopes are configurable and can be set in [monkey365.config](../configuration/configuration-file.md) configuration file under the scopes section, as shown below:

```json
"mgGraph":{
	"useMgGraph": "true",
	"scopes": [
		"User.Read.All",
		"Application.Read.All",
		"Policy.Read.All",
		"Organization.Read.All",
		"OrgSettings-AppsAndServices.Read.All",
		"RoleManagement.Read.Directory",
		"GroupMember.Read.All",
		"Directory.Read.All",
		"PrivilegedEligibilitySchedule.Read.AzureADGroup",
		"PrivilegedAccess.Read.AzureADGroup",
		"RoleManagementPolicy.Read.AzureADGroup",
		"Group.Read.All",
		"SecurityEvents.Read.All",
		"IdentityRiskEvent.Read.All",
		"UserAuthenticationMethod.Read.All",
		"AuditLog.Read.All",
		"AccessReview.Read.All"
	]
}
}
```

???+ note
	If you are authenticating with the Microsoft Graph Client ID for the first time, you will be prompted to grant the necessary permissions, as shown below:
	![](../assets/images/consent.png)