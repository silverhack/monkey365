---
author: Juan Garrido
---

## Interactive browser authentication

Interactive browser authentication enables the `Monkey365` PowerShell module for all operations allowed by the interactive login credentials. Please, note that if you are using a user with owner or administrator permissions within the subscription in scope, the monkey365 tool will inherent these permissions to all resources in that subscription without having to assign any specific permissions. Please, see the [permissions](../permissions.md) for further details.

## Usage Examples

```PowerShell

$param = @{
    Instance = 'Microsoft365';
    Analysis = 'SharePointOnline','ExchangeOnline';
    PromptBehavior = 'SelectAccount';
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param

```

## References

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows</a>
