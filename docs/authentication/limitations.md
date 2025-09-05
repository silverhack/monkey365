---
author: Juan Garrido
---

# Current limitations

Review the following sections to learn about current limitations of Monkey365 on NIX environments.

## SharePoint Online in PowerShell Core

When using the Interactive authentication flow, Monkey365 relies on the **SharePoint Online Management Shell ClientId**. To support .NET Core, which lacks a built-in user interface, developers must configure the reply URI as `http://localhost`. However, since the SharePoint Online Management Shell is not set up to accept `http://localhost` as a reply URI, certain authentication methods like [Interactive browser authentication](authFlows/interactive.md) or [Authentication with a username and password](authFlows/ropc.md) are not compatible with SharePoint Online when Monkey365 is run via PowerShell Core (PowerShell 6+, including NIX environments).

To avoid authentication issues, consider the following alternatives:

* Switch Authentication Flow

    Use [Device Code Authentication](authFlows/devicecode.md) or [Certificate-based Authentication](authFlows/sp.md) instead of the Interactive flow.

* Run Monkey365 with PowerShell V5

	This option is only applicable in Windows environments and allows compatibility with the default authentication setup.

* Use the `-ForceMSALDesktop` Parameter

	This forces PowerShell 6 and above to load the .NET MSAL desktop libraries instead of the .NET Core versions. This workaround is also limited to Windows environments.

## References

<a href='https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri' target='_blank'>https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/default-reply-uri</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#authorization-code</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/authentication/concepts-azure-multi-factor-authentication-prompts-session-lifetime</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/reply-url</a>