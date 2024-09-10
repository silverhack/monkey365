---
author: Juan Garrido
---


## Export To JSON

The JSON output is based on the <a href="https://schema.ocsf.io/1.1.0/classes/detection_finding?extensions=" target="_blank">Open CyberSecurity Schema Framework schema</a> for cloud findings.

You can easily export all findings as a JSON file. Simply select `-ExportTo JSON` as shown below:

``` PowerShell
$p = @{
    Instance = 'Azure';
    Analysis = 'All';
    PromptBehavior = 'SelectAccount';
    AllSubscriptions = $true;
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'JSON';
}
Invoke-Monkey365 @p
```

## JSON Properties

The following is an example of output:

``` json
{
  "metadata": {
    "eventCode": "aad_sbd_enabled",
    "product": {
      "name": "Monkey365",
      "vendorName": "Monkey365",
      "version": "0.98"
    },
    "version": "1.1.0"
  },
  "severityId": 0,
  "severity": "Unknown",
  "status": "New",
  "statusCode": "pass",
  "statusDetail": null,
  "statusId": 1,
  "unmapped": {
    "provider": "EntraID",
    "pluginId": "aad0024",
    "apiType": "EntraIDPortal",
    "resource": "EntraIDPortal"
  },
  "activityName": "Create",
  "activityId": 1,
  "findingInfo": {
    "createdTime": "2024-08-21T11:47:48Z",
    "description": "Security defaults in Microsoft Entra ID (Azure Active Directory) make it easier to be secure and help protect your organization. Security defaults
 contain preconfigured security settings for common attacks.Microsoft is making security defaults available to everyone. The goal is to ensure that all organizations 
have a basic level of security-enabled at no extra cost. The use of security defaults however will prohibit custom settings which are being set with more advanced set
tings.",
    "productId": "Monkey365",
    "title": "Ensure Security Defaults is disabled on Microsoft Entra ID",
    "id": "Monkey365-aad-sbd-enabled-a4807c0361194a9a9da91e02458bd3ff-zxuQ2OfB3Ag"
  },
  "resources": {
    "cloudPartition": "6",
    "region": null,
    "data": null,
    "group": {
      "name": "General"
    },
    "labels": null,
    "name": null,
    "type": null,
    "id": null
  },
  "categoryName": "Findings",
  "categoryId": 2,
  "className": "Detection",
  "classId": 2004,
  "cloud": {
    "account": {
      "name": "Contoso",
      "type": "AzureADAccount",
      "typeId": "6",
      "id": "a4807c03-6119-4a9a-9da9-1e02458bd3ff"
    },
    "organization": {
      "name": "Contoso",
      "id": "a4807c03-6119-4a9a-9da9-1e02458bd3ff"
    },
    "provider": "Microsoft365",
    "region": "global"
  },
  "time": "2024-08-21T11:47:48Z",
  "remediation": {
    "description": "From Azure Console1. Sign in to the Azure portal as a security administrator, Conditional Access administrator, or global administrator.2. Bro
wse to Microsoft Entra ID  Properties.3. Select Manage security defaults.4. Set the Enable security defaults toggle to No.5. Select Save.",
    "references": [
      "https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/users-default-permissions",
      "http://www.rebeladmin.com/2019/04/step-step-guide-restrict-azure-ad-administration-portal/",
      "https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/concept-fundamentals-security-defaults",
      "https://techcommunity.microsoft.com/t5/azure-active-directory-identity/introducing-security-defaults/ba-p/1061414"
    ]
  },
  "typeId": 200401,
  "typeName": "Create"
}
```