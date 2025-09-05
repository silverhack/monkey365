---
author: Juan Garrido
---
Monkey365 offers many ways to connect to both Azure and Microsoft 365 environments. This section covers the authentication process against Azure or Microsoft 365, as well as the supported authentication options, including:

* [Interactive browser authentication](authFlows/interactive.md) 
* [Authentication with a username and password](authFlows/ropc.md)
* [Device Code Authentication](authFlows/devicecode.md)
* [Client Credential Authentication](authFlows/sp.md)

## Using service principals

Service principals in Microsoft Entra serve as representations of applications within a specific tenant. They outline the application's capabilities, the resources it can interact with, and the users permitted to utilize it. When an application is registered in Microsoft Entra ID, a service principal is automatically generated, enabling secure authentication and resource access for the application.

To set up a service principal for use with Monkey365, you'll need to follow these steps:

* Register an Application in Microsoft Entra ID
* Create a Client Secret or Certificate
* Assign API Permissions
* Assign the required roles

Check the [Service Principal authentication section](sp_authentication/getting_started.md) for manual steps. Additionally, Monkey365 includes a [built-in utility](sp_authentication/automatic_setup.md) that streamlines the creation and configuration of Entra ID applications.
