---
author: Juan Garrido
---

# Slack logger

The Slack plugin sends log events to a ```slack``` channel.

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
                "name": "Slack",
                "type": "Slack",
                "configuration": {
                    "webHook": "https://hooks.slack.com/services/00000000000/00000000000/00000000000000000",
                    "icon_emoji": ":ghost:",
                    "username": "monkey365",
                    "channel": "#monkey365",
                    "onlyExceptions": true
                }
            }
        ]
    }
```

# Configuration
* name - Channel name
* type - File
* webHook - your Slack WebHook <a href='https://api.slack.com/messaging/webhooks'>See the slack web api docs</a>
* icon_emoji - the icon to use for the message
* username - the username to display with the message
* channel - the channel to send log messages
* onlyExceptions - Set to true in order to send only exceptions streams to Slack