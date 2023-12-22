---
author: Juan Garrido
---

# Current limitations

Review the following sections to learn about current limitations of Monkey365 on NIX environments.

## SharePoint Online in PowerShell Core

Monkey365 is using the **SharePoint Online Management Shell** ClientId when Interactive authentication flow is used. In order to give support to .NET Core, developers must set the reply URI to **http://localhost**, because .NET Core does not have an integrated UI. Due to **SharePoint Online Management Shell** is not configured to use **http://localhost** in the reply URI, authentication methods such as [Interactive browser authentication](../authFlows/interactive) or [Authentication with a username and password](../authFlows/ropc) are not supported in SharePoint Online when Monkey365 is executed using PowerShell Core (PowerShell 6 or later and PowerShell in NIX environments). The following options are available to avoid authentication issues:

### Change the authentication flow

* Change the authentication flow to [Device Code Authentication](../authFlows/devicecode) or [Certificate-based Authentication](../authFlows/sp).

* Execute Monkey365 using the PowerShell V5 Default version. <span style="color:red">*Only valid on Windows environments*</span>

* Use the `-ForceMSALDesktop` parameter will force PowerShell 6 and higher to load .NET MSAL libraries instead of .NET core versions. <span style="color:red">*Only valid on Windows environments*</span>

## References

<a href='https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri' target='_blank'>https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url</a>