---
author: Juan Garrido
---

# Teams logger

The Teams plugin sends log events to a ```Teams``` channel.

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
                "name": "Teams",
                "type": "Teams",
                "configuration": {
                    "webHook": "https://tenantName.webhook.office.com/webhookb2/00000000000/00000000000/00000000000000000",
                    "onlyExceptions": true
                }
            }
        ]
    }
```

# Configuration
* name - Channel name
* type - Teams
* webHook - your Teams WebHook <a href='https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook' target='_blank'>See the Microsoft Teams docs</a>
* onlyExceptions - Set to true in order to send only exceptions streams to Slack