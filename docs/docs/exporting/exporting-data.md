---
author: Juan Garrido
---


Monkey365 has built-in support for exporting data to a large variety of formats, including CSV, CLIXML and JSON. For example, the CSV output format is a comma-separated output that can be imported into i.e., Excel spreadsheets. The JSON format is pretty similar to JavaScript object, so it can be used as a data format by any programming language. Finally, CLIXML will create an XML-based representation of all findings and will store it in a file. This section page documents how Monkey365's data may be exported to these formats.

* [Export Data to CSV](export-csv.md) 
* [Export Data to HTML](export-html.md)
* [Export Data to CLIXML](export-clixml.md)
* [Export Data to JSON](export-json.md)

## Data Location

Depending on what format you are exporting to, the ```-ExportTo``` parameter presents slightly different options. When ```-OutDir``` is specified, Monkey365 writes the exported data to the provided path. When ```-OutDir``` is not specified, Monkey365 creates the output under the current working directory.

By default, exported data is stored using the following structure:

```./monkey365-output/$GUID/$FORMAT/$FILE```

For example, if Monkey365 is executed from ```/home/user/cloud_reports```, the default output path will be:

```/home/user/cloud_reports/monkey365-output/$GUID/$FORMAT/$FILE```

The following demonstrates some examples in which the data may be programmatically accessed using various common languages.

### Import JSON data in Python

The following code snippet illustrates how one may load the Monkey365 data in a Python script (assuming that report data was previously exported to JSON format):

``` json
import json

file = 'C:/temp/monkey365-output/00000000-0000-0000-0000-000000000000/json/monkey3650000000000000000000000000000000020240902155926.json'

with open(file) as f:

    json_data = json.load(f)

    return json_data
```

### Import JSON data in PowerShell

The following code snippet illustrates how one may load the Monkey365 data in a PowerShell script (assuming that report data was previously exported to JSON format):

``` powershell
PS C:\temp> $json_data = (Get-Content -Raw .\monkey365-output\00000000-0000-0000-0000-000000000000\json\monkey3650000000000000000000000000000000020240902155926.json) | ConvertFrom-Json
```

### Import CLIXML data in PowerShell

The following code snippet illustrates how one may load the Monkey365 data in a PowerShell script (assuming that report data was previously exported to CLIXML format):

``` powershell
PS C:\temp> $clixml_data = (Get-Content -Raw .\monkey365-output\00000000-0000-0000-0000-000000000000\clixml\monkey3650000000000000000000000000000000020240902155926.clixml)
```

