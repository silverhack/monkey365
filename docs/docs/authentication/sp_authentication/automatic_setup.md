---
author: Juan Garrido
---

# Getting Started

Monkey365 includes a built-in utility that streamlines the creation and configuration of Entra ID applications for the following Microsoft services:

* Microsoft Graph
* Microsoft Teams
* Exchange Online
* SharePoint Online

The utility automates the creation of an Entra ID application, configures permissions based on the selected services, and generates a certificate for authentication, which it then uploaded. It also assigns service-specific roles to the application. For instance, if SharePoint Online is chosen, the utility will grant the application the `SharePoint Online Administrator`role. If Exchange Online is chosen, the helper will grant the application the `Global Reader` role.

# Automatic Application Setup with Monkey365

## Running the Utility with Default Settings

To run the utility with default settings from the Monkey365 installation directory, use the following:

```PowerShell
$p = @{
    TenantId = '00000000-0000-0000-0000-000000000000';
    Services = 'ExchangeOnline','MicrosoftGraph','MicrosoftTeams','SharePointOnline';
}
Register-Monkey365Application @p
```

## Customizing Parameters (e.g., Certificate)

To override default settings—such as specifying a custom certificate—use this version of the script:

```PowerShell
$p = @{
    TenantId = '00000000-0000-0000-0000-000000000000';
    Services = 'ExchangeOnline','MicrosoftGraph','MicrosoftTeams','SharePointOnline';
    Certificate = 'C:\Monkey365.cer'
}
Register-Monkey365Application @p
```

After registering the application, you may need to manually grant admin consent for required permissions. To do this, navigate to:

	* Azure Entra ID > App registrations
	* Select the Monkey365 app
	* Go to API permissions, and click !Grant admin consent for *your organisation*.


???+ note
	You will need the following for Monkey365:
	
	- Tenant ID: Found under Azure Entra ID > Overview.
	- Client ID: From the app registration overview.
	- Certificate: The one you created earlier.