---
author: Juan Garrido
---

## Resource Owner Password Credentials

The Microsoft identity platform supports the OAuth 2.0 Resource Owner Password Credentials (ROPC) grant, which allows an application to sign in the user by directly handling their password. In this flow, client identification (e.g. user's email address) and user's credentials is sent to the identity server, and then a token is received.

## Security Note
There are multiple scenarios in which ROPC is not supported, such as hybrid identity federation access (Azure AD and ADFS) or when conditional access policies are enabled. There are more secure and available recommended alternatives, such as [Interactive authentication](interactive.md) or [Service Principal](sp.md). 

## Usage Examples

```PowerShell

$cred = Get-Credential

$param = @{
    Instance = 'Microsoft365';
    Analysis = 'SharePointOnline','ExchangeOnline';
    UserCredentials = $cred;
	TenantId = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'PRINT';
}

$assets = Invoke-Monkey365 @param

```

## References

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth-ropc' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth-ropc</a>