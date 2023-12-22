---
author: Juan Garrido
---

## Service Principal Authentication

This type of grant is commonly used for machine-to-machine interactions that must run in the background, such as daemons, or service accounts. In this case, Microsoft Entra ID authenticates and authorizes the app rather than a user. During this step, the client has to authenticate itself to Microsoft Entra ID. The Microsoft identity platform allows the confidential client to authenticate using a shared secret, certificate or federated credential.

## Usage Examples

### Client secret in command-line flag

```PowerShell

$param = @{
    ClientId = '00000000-0000-0000-0000-000000000000';
    ClientSecret = ("MySuperClientSecret" | ConvertTo-SecureString -AsPlainText -Force)
    Instance = 'Azure';
    Analysis = 'All';
    subscriptions = '00000000-0000-0000-0000-000000000000';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = @("HTML");
}
Invoke-Monkey365 @param

```

### Client certificate in command-line flag

```PowerShell

$param = @{
    ClientId = '00000000-0000-0000-0000-000000000000';
    certificate = 'C:\monkey365\testapp.pfx';
    CertFilePassword = ("MySuperCertSecret" | ConvertTo-SecureString -AsPlainText -Force);
    Instance = 'Microsoft365';
    Analysis = 'SharePointOnline';
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = @("HTML");
}
Invoke-Monkey365 @param

```

## References

<a href='https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread' target='_blank'>https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread</a>

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app</a>

<a href='https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps' target='_blank'>https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps</a>

<a href='https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs' target='_blank'>https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs</a>