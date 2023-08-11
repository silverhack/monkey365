---
author: Juan Garrido
---

# Current limitations

Review the following sections to learn about current limitations of Monkey365 on NIX environments.

## Microsoft purview (Security & Compliance) in NIX environments

In the new version of Monkey365, Security and Compliance was fully migrated from WSMAN/RemotePS to REST-based PowerShell. On the other hand, some commands were not fully migrated from Microsoft, and the company has decided to delay the deprecation of the RPS protocol until October 2023. Some CmdLets are requiring an active PowerShell PSSession because those commands doesn't return (not migrated yet) information for REST-based connections, and for that reason some commands may not work on NIX operating systems. 

## SharePoint Online in NIX environments

Monkey365 is using the **SharePoint Online Management Shell** ClientId when Interactive authentication flow is used. In order to give support to .NET Core, developers must set the reply URI to **http://localhost**, because .NET Core does not have an integrated UI. Due to **SharePoint Online Management Shell** is not configured to use **http://localhost** in the reply URI, authentication methods such as [Interactive browser authentication](../authFlows/interactive) or [Authentication with a username and password](../authFlows/ropc) are not supported in SharePoint Online when Monkey365 is used in Linux environments. Valid authentication methods are [Device Code Authentication](../authFlows/devicecode) or [Certificate-based Authentication](../authFlows/sp).  

## References

<a href='https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri' target='_blank'>https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url</a>

<a href='https://techcommunity.microsoft.com/t5/exchange-team-blog/deprecation-of-remote-powershell-in-exchange-online-re-enabling/ba-p/3779692' target='_blank'>https://techcommunity.microsoft.com/t5/exchange-team-blog/deprecation-of-remote-powershell-in-exchange-online-re-enabling/ba-p/3779692</a>