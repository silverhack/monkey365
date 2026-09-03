---
author: Juan Garrido
---

The module will not change or modify any assets deployed in an Azure subscription. Monkey365's only perform read-only access operations. Monkey365 cannot manipulate or change data and cannot influence the resources within Azure or Microsoft 365.

Depending on what workloads you are trying to connect, Monkey365 will require that the provided identity have the following roles according to the principle of least privilege:

## Interactive authentication

* Microsoft Entra ID and Azure environments
    * **Global Reader** and **Security Reader** roles in all the subscriptions to assess
* Microsoft 365 environments
    * Grant the given identity the role of **Global Reader**
    * For SharePoint Online, grant the given identity the role of **Sharepoint Administrator**. Please note that Global Reader role can't access to SharePoint admin features as a reader using PowerShell. Please refer to the <a href='https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#global-reader' target='_blank'>Global Reader</a> notes on Microsoft.

## Service Principal Authentication

Access to APIs and Microsoft services require configuration of access scopes and roles. If you want a client application to access Azure and Microsoft 365 services, configure permissions to access the API in the app registration. The following permissions must be granted to the client application created in Azure:

* Microsoft Entra ID environment
    * User.Read.All,
	* Application.Read.All,
	* Policy.Read.All,
	* Organization.Read.All,
	* RoleManagement.Read.Directory,
	* GroupMember.Read.All,
	* Directory.Read.All,
	* PrivilegedEligibilitySchedule.Read.AzureADGroup,
	* PrivilegedAccess.Read.AzureADGroup,
	* RoleManagementPolicy.Read.AzureADGroup,
	* Group.Read.All,
	* SecurityEvents.Read.All,
	* IdentityRiskEvent.Read.All
	* UserAuthenticationMethod.Read.All
	
* Azure
    * **Reader** role in all the subscriptions to assess
* SharePoint Online
	* Sites.FullControl.All
	* Grant the given identity the role of **SharePoint Administrator**
* Exchange Online and Security and Compliance
    * Exchange.ManageAsApp
	* Grant the given identity the role of **Global Reader**

See the [authentication section](../authentication/overview.md) for further details on available authentication methods and permission references.

## References

<a href='https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps' target='_blank'>https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps</a>

<a href='https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread' target='_blank'>https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread</a>


