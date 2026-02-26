---
author: Juan Garrido
---

# Using Access Tokens with Monkey365

Monkey365 supports direct authentication using **access tokens**, enabling fully non‑interactive execution for automation, CI/CD pipelines or service‑principal–based workflows.  
This feature allows users to pass one or more access tokens to Monkey365, which will automatically route each token to the correct API based on its **audience** (`aud`) claim.

## Overview

You can provide access tokens to Monkey365 by using the `-AccessToken` parameter. The parameter accepts a single token (string) or multiple tokens (array of strings). 

Each token is inspected to determine which Microsoft 365 or Azure service it applies to. Monkey365 then uses the appropriate token when making API calls.

???+ note
	Expired or malformed tokens are ignored.
	

## Usage Examples

### Passing a Single Token

```powershell
$graph = az account get-access-token --resource https://graph.microsoft.com/ --query accessToken -o tsv

$p = @{
    AccessToken = $graph;
    IncludeEntraId = $true;
    TenantId = "00000000-0000-0000-0000-000000000000";
    Verbose = $true;
    InformationAction = "Continue"
}
Invoke-Monkey365 @p
```

### Passing Multiple Tokens

```powershell
$azureRM = az account get-access-token --query accessToken -o tsv
$graph = az account get-access-token --resource https://graph.microsoft.com/ --query accessToken -o tsv
$storage = az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv
$vault = az account get-access-token --resource https://vault.azure.net --query accessToken -o tsv

$accessTokens = [System.Collections.Generic.List[System.String]]::new()
[void]$accessTokens.Add($azureRM);
[void]$accessTokens.Add($graph);
[void]$accessTokens.Add($storage);
[void]$accessTokens.Add($vault);

$p = @{
    Instance = "Azure";
    Collect = "All";
    AccessToken = $accessTokens;
    IncludeEntraId = $true;
    TenantId = "00000000-0000-0000-0000-000000000000";
    Verbose = $true;
    InformationAction = "Continue"
}
Invoke-Monkey365 @p
```
This allows Monkey365 to:

- Query EntraID via Microsoft Graph
- Enumerate Azure subscriptions and resources via ARM

All without any interactive login.

### Notes & Recommendations
- Tokens must be valid JWT access tokens.
- Monkey365 does not refresh tokens.
- Ensure tokens include the correct scopes or resource audiences.

### Troubleshooting

#### Monkey365 reports "Invalid token"
- Ensure the token is an access token, not an ID token.
- Verify the aud claim matches a supported API.
- Check token expiration (exp claim).

#### API calls fail with 401/403
- Token may be missing required scopes/permissions.
- Service principal may not have required roles (e.g., Reader on subscription).