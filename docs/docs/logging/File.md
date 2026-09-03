---
author: Juan Garrido
---

# File logger

The File plugin writes log events to a file. It supports which ```eventType``` can be written to a file.

# Example

``` json
"logging": {
        "default":[
            {
                "name": "File",
                "type": "File",
                "configuration": {
                    "filename": "monkey365_yyyyMMddhhmmss.log",
                    "includeExceptions": false,
                    "includeDebug": false,
                    "includeVerbose": false,
                    "includeError": false
                }
            }
        ],
        "loggers":[
            {
                "name": "File",
                "type": "File",
                "configuration": {
                    "filename": "monkey365_exceptions_yyyyMMddhhmmss.log",
                    "includeExceptions": true,
                    "includeDebug": true,
                    "includeVerbose": true,
                    "includeInfo": false
                }
            }
        ]
    }
```

# Configuration
* name - Channel name
* type - File
* filename - The path of the file where logs will be written
* includeExceptions - whether or no exception streams will be written to file
* includeDebug - whether or no debug streams will be written to file
* includeVerbose - whether or no verbose streams will be written to file
* includeInfo - whether or no information streams will be written to file