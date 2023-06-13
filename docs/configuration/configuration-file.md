---
author: Juan Garrido
---

The Monkey365 configuration file contains settings that are used for managing CLI behavior. The configuration file itself is located at ```$monkey365_DIR/config/monkey_365.config```.

Configuration file is written in the JSON file format. This file format is followed by a list of key-value entries. Also, Boolean is case-insensitive, and is represented by ```True``` (Enabled/must check) and ```False``` (Disabled/not check).

The following is an example of a configuration file that sets up Monkey365 to use the ```1.6``` version of the Azure AD API but is also setting the ```getUsersWithAADInternalAPI``` key to ```True```. With this change, Monkey365 will use the internal (1.6-internal) API version to extract information regarding Azure AD users:

```json
"azuread": {
	"useMsGraph": "true",
	"auditLog":{
		"enabled": "false",
		"AuditLogDaysAgo": "-7"
	},
	"provider": {
		"graph":{
			"api_version": "1.6",
			"internal_api_version": "1.61-internal",
			"getUsersWithAADInternalAPI": "true"
		},
		"portal":{
			"GetManagedApplicationsByPrincipalId": "true"
		},
		"msgraph":{
			"api_version": "V1.0"
		}
	}
}
```
