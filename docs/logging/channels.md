---
author: Juan Garrido
---

# Channels

Channels serialise PowerShell log events to some form of output. Channels can be configured to write stream data to files, send emails, send data over the network, etc... For example:

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
            },
            {
                "name": "Slack",
                "type": "Slack",
                "configuration": {
                    "webHook": "https://hooks.slack.com/services/00000000000/00000000000/00000000000000000",
                    "as_user": "false",
                    "icon_emoji": ":ghost:",
                    "username": "monkey365",
                    "channel": "#monkey365",
                    "onlyExceptions": true
                }
            }
        ]
    }
```

In the above example, configuration file defines two channels named ```File``` and ```Slack```.