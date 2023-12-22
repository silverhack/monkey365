---
author: Juan Garrido
---

## Device code authentication

Interactive authentication with Microsoft Entra ID requires a web browser. However, in operating systems that do not provide a Web browser, such as containers, command line tools or non-gui systems, Device code flow lets the user use another computer to sign-in interactively. The tokens will be obtained through a two-step process.

## Usage Examples

```PowerShell

$param = @{
    Instance = 'Microsoft365';
    Analysis = 'SharePointOnline';
    DeviceCode = $true;
    IncludeEntraID = $true;
    ExportTo = 'PRINT';
}
$assets = Invoke-Monkey365 @param

```

## References

<a href='https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-device-code' target='_blank'>https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-device-code</a>

