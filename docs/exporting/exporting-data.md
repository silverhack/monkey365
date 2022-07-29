---
author: Juan Garrido
---


Monkey365 has built-in support for exporting data to a large variety of formats, including CSV and JSON. For example, the CSV output format is a comma-separated output that can be imported into i.e., Excel spreadsheets. The JSON format is pretty similar to JavaScript object, so it can be used as a data format by any programming language. This section page documents how Monkey365's data may be exported to these formats.

## Data Location

Depending on what format you are exporting to, the ```-ExportTo``` parameter presents you with slightly different options. Once Monkey365 has finished running, all the exported data are stored under Monkey365/monkey-reports/$GUID/$FORMAT/$FILE. The following demonstrates some examples in which the data may be programmatically accessed using various common languages.

### Import JSON data in Python

The following code snippet illustrates how one may load the Monkey365 data in a Python script (assuming that report data was previously exported to JSON format):

``` json
import json

file = 'C:/temp/monkey365/monkey-reports/00000000-0000-0000-0000-000000000000/json/aad_domain_users.json'

with open(file) as f:

    json_data = json.load(f)

    return json_data
```

### Import JSON data in PowerShell

The following code snippet illustrates how one may load the Monkey365 data in a PowerShell script (assuming that report data was previously exported to JSON format):

``` powershell
PS C:\temp\monkey365> $json_data = (Get-Content -Raw .\monkey-reports\00000000-0000-0000-0000-000000000000\json\aad_domain_users.json) | ConvertFrom-Json
```

