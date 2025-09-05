---
author: Juan Garrido
---

# Supported Authentication Methods Matrix

The following table shows the supported authentication methods for each type of service.

## Windows Environments

| Microsoft Service | Interactive browser authentication | Device code authentication| SPA (Client Secret) | SPA (Certificate Secret) | ROPC |
| ------------------------------------- | ------------ |------------ |------------ |------------ |------------ |
| Microsoft Entra ID Portal|✔️|✔️|❌️[^1]|❌️[^1]|✔️|
| Entra ID GraphV2|✔️|✔️|✔️|✔️|✔️|
| Azure services|✔️|✔️|✔️|✔️|✔️|
| Exchange Online|✔️|✔️|✔️|✔️|✔️|
| Microsoft 365 backend API|✔️|✔️|❌️[^2]|❌️[^2]|✔️|
| Purview|✔️|✔️|✔️|✔️|✔️|
| Microsoft Teams|✔️|✔️|✔️|✔️|✔️|
| SharePoint Online|✔️|✔️|❌️[^3]|✔️|✔️|
| Microsoft Fabric|✔️|✔️|✔️|✔️|✔️|

## NIX Environments (.NET Core)

| Microsoft Service | Interactive browser authentication | Device code authentication| SPA (Client Secret) | SPA (Certificate Secret) | ROPC |
| ------------------------------------- | ------------ |------------ |------------ |------------ |------------ |
| Microsoft Entra ID Portal|✔️|✔️|❌️[^1]|❌️[^1]|✔️|
| Entra ID GraphV2|✔️|✔️|✔️|✔️|✔️|
| Azure services|✔️|✔️|✔️|✔️|✔️|
| Exchange Online|✔️|✔️|✔️|✔️|✔️|
| Microsoft 365 backend API|✔️|✔️|❌️[^2]|❌️[^2]|✔️|
| Purview|✔️|✔️|✔️|✔️|✔️|
| Microsoft Teams|✔️|✔️|✔️|✔️|✔️|
| SharePoint Online|❌️[^4]|✔️|❌️[^3]|✔️|❌️[^4]|
| Microsoft Fabric|✔️|✔️|✔️|✔️|✔️|


[^1]: Service Principal authentication is not supported in <a href='https://main.iam.ad.ext.azure.com/qos' target='_blank'>backend Entra ID APIs (ADIbizaUX)</a>
[^2]: Service Principal authentication is not supported in Microsoft 365 backend APIs
[^3]: Authentication with client secret is not supported in SharePoint Online. You can find more information <a href='https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread#:~:text=FAQ' target='_blank'>here</a> and <a href='https://medium.com/@rawandhawez/sharepoint-app-only-auth-when-client-secrets-fail-and-certificates-prevail-ca230b91a601' target='_blank'>here</a>
[^4]: SharePoint Online Management Shell Client Id is not supporting interactive authentication in .NET core. You can find more information [here](../authentication/limitations.md)