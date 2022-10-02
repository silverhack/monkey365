---
author: Juan Garrido
---

The module will not change or modify any assets deployed in an Azure subscription. Monkey365's only perform read-only access operations. Monkey365 cannot manipulate or change data and cannot influence the resources within Azure or Microsoft 365.

Depending on what workloads you are trying to connect, Monkey365 will require that the provided identity have the following roles according to the principle of least privilege:

* Azure AD and Azure environments
    * **Global Reader** and **Security Reader** roles in all the subscriptions to assess
* Microsoft 365 environments
    * Grant the given identity the role of **Global Reader**
    * For SharePoint Online, grant the given identity the role of **Sharepoint Administrator**. Please note that Global Reader role can't access to SharePoint admin features as a reader using PowerShell. Please refer to the <a href='https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#global-reader' target='_blank'>Global Reader</a> notes on Microsoft.
