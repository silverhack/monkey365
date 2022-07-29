---
author: Juan Garrido
---

# Introduction

The internal logging module provides a multi-channel logger which is used internally. The logger module is inspired by the excellent project <a href='https://github.com/EsOsO/Logging/' target='_blank'>Powershell Logging Module</a>. This section outlines how to configure it.

The internal module intercepts the Write-Information, Write-Warning, Write-Verbose, Write-Debug and Write-Error cmdlets by using proxy functions to first send messages to custom channels before sending stream data to their original commands from the <a href='https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/?view=powershell-7.2' target='_blank'>Microsoft.PowerShell.Utility</a> module.

The ```MonkeyLogger``` will send stream data to enabled channels, which needs to be configured prior using. Each of these listeners will receive each of the stream data and then will be sent to some form of output.

The easiest way to configure ```MonkeyLogger``` is to have configured listeners in the ```logging``` section within the ```monkey365/config/monkey_365.config``` file. See below for a practical example.

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
	]
}
```

In the above example, configuration file defines one type named ```File```.