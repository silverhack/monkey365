---
author: Juan Garrido
---

Although there is already support for a variety of file formats (CSV, JSON), there is also support for exporting all data to an EXCEL spreadsheet. Currently, it supports style modification, chart creation, company logo or independent language support. At the moment Office Excel 2010/2013/2016 are supported by Monkey365. The following example can be used to export all data to an Excel file.

``` powershell
$param = @{
    Instance = 'Azure';
    Analysis = 'All';
    PromptBehavior = 'SelectAccount';
    AllSubscriptions = $true;
    TenantID = '00000000-0000-0000-0000-000000000000';
    ExportTo = 'EXCEL';
}
$assets = Invoke-Monkey365 @param
```

Please, note that the EXCEL application must be installed on the OS, as the script will create the Excel file by using the EXCEL COM interface.

Please, also note that the EXCEL output is maintained only for legacy purposes, and it will be retired at some future.
