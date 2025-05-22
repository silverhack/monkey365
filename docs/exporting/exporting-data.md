---
author: Juan Garrido
---


Monkey365 has built-in support for exporting data to a large variety of formats, including CSV, CLIXML and JSON. For example, the CSV output format is a comma-separated output that can be imported into i.e., Excel spreadsheets. The JSON format is pretty similar to JavaScript object, so it can be used as a data format by any programming language. Finally, CLIXML will create an XML-based representation of all findings and will store it in a file. This section page documents how Monkey365's data may be exported to these formats.

* [Export Data to CSV](export-csv.md) 
* [Export Data to HTML](export-html.md)
* [Export Data to CLIXML](export-clixml.md)
* [Export Data to JSON](export-json.md)

## Data Location

Depending on what format you are exporting to, the ```-ExportTo``` parameter presents you with slightly different options. Once Monkey365 has finished running, all the exported data are stored under Monkey365/monkey-reports/$GUID/$FORMAT/$FILE. The following demonstrates some examples in which the data may be programmatically accessed using various common languages.

### Import JSON data in Python

The following code snippet illustrates how one may load the Monkey365 data in a Python script (assuming that report data was previously exported to JSON format):

``` json
import json

file = 'C:/temp/monkey365/monkey-reports/00000000-0000-0000-0000-000000000000/json/monkey3650000000000000000000000000000000020240902155926.json'

with open(file) as f:

    json_data = json.load(f)

    return json_data
```

### Import JSON data in PowerShell

The following code snippet illustrates how one may load the Monkey365 data in a PowerShell script (assuming that report data was previously exported to JSON format):

``` powershell
PS C:\temp\monkey365> $json_data = (Get-Content -Raw .\monkey-reports\00000000-0000-0000-0000-000000000000\json\monkey3650000000000000000000000000000000020240902155926.json) | ConvertFrom-Json
```

### Import CLIXML data in PowerShell

The following code snippet illustrates how one may load the Monkey365 data in a PowerShell script (assuming that report data was previously exported to CLIXML format):

``` powershell
PS C:\temp\monkey365> $clixml_data = (Get-Content -Raw .\monkey-reports\00000000-0000-0000-0000-000000000000\clixml\monkey3650000000000000000000000000000000020240902155926.clixml)
```

