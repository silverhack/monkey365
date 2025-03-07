---
author: Juan Garrido
---

# Overview

Monkey365 helps streamline the process of performing not only Microsoft 365, but also Azure subscriptions and Microsoft Entra ID Security Reviews.

200+ checks covering industry defined security best practices for Microsoft 365, Azure and Microsoft Entra ID.

All rulesets are located at ```$monkey365_DIR/rules/ruleset``` directory.

Monkey365 will help consultants to assess cloud environment and to analyze the risk factors according to controls and best practices. The report will contain structured data for quick checking and verification of the results.

# Rules

A Monkey365 rule consists of instructions designed to query cloud data to identify misconfigurations.
The Monkey365 core analyzer processes user-defined rules, assesses them against cloud data, and generates violations for any matched rules. A set of one or more rules forms a *Ruleset*, which helps organize multiple rules that work towards a common objective.

# Rule

A Rule, written in JSON, includes metadata, conditions, and actions. It directs the core analyzer to execute specific actions when the defined conditions are met.

# Rule Metadata

Rule metadata contains general information about a rule:

1.- ```serviceType```: This is the friendly name of the application/service that is checked, displayed on the HTML dashboard.

2.- ```serviceName```: This is the friendly name of the provider, which is displayed on the HTML sidebar.

3.- ```displayName```: The rule name.

4.- ```description```: The rule description. Rule description supports <a href='https://en.wikipedia.org/wiki/Markdown' target='_blank'>Markdown</a>. That way you can add links and apply minor text styles.

5.- ```references```: This parameter is optional. You can add external links in order to help consultants find more information about findings. Result output will sometimes be more than enough to explain what the issue is, but it can also be beneficial to explain why an issue exists, and this is a great place to do that. Additional elements such as remediation or rationale can be added to existing JSON rule. Both of them supports <a href='https://en.wikipedia.org/wiki/Markdown' target='_blank'>Markdown</a>.

6.- The ```query``` property determines the checks Monkey365 will use to search for misconfigurations.

7.-  ```idSuffix```: UniqueID for the rule.

# Rule Levels

The rule's severity is specified in the metadata using the *level* field. The severity can be one of the following values:

* informational
* low
* medium
* high
* critical

# Rule Status

If the rule is executed correctly (error-free), the core analyzer will assign a status property based on the following criteria:

* Pass: If the rule's query meets the configured value.
* Fail: If the rule's query does not meet the configured value.
* Manual: If the query is empty, the analyzer will flag the rule as manual, indicating that manual intervention is needed.

# Rule Condition

Every rule should have a query block that contains exactly one or more conditions. A condition defines a search query to be evaluated against the input data.

```Json
"query": [
  {
	"operator": "and",
	"filter": [
	  {
		"conditions": [
		  [
			"isEnabled",
			"eq",
			"True"
		  ],
		  [
			"policyName",
			"match",
			"Built-In"
		  ]
		],
		"operator": "and"
	  },
	  {
		"conditions": [
		  [
			"Policy.ScanUrls",
			"eq",
			"False"
		  ],
		  [
			"Policy.AllowClickThrough",
			"eq",
			"True"
		  ],
		  [
			"Policy.EnableSafeLinksForEmail",
			"eq",
			"False"
		  ]
		],
		"operator": "or"
	  }
	]
  }
]      	
```

Multiple PowerShell comparison operators are supported. The following <a href='https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-7.2' target='_blank'>link</a> is a list of comparison operators supported by PowerShell.

# Ruleset

A set of one or more rules forms Ruleset, which helps organize multiple rules that work towards a common objective.

A ruleset is formed by placing one or more JSON rule files in a directory and creating a ruleset.json within it.

The ruleset file stores metadata of the Ruleset, as described [here](../custom-ruleset) 

# Supported standards

By default, the HTML report shows you the CIS (Center for Internet Security) Benchmark. The CIS Benchmarks for Azure and Microsoft 365 are guidelines for security and compliance best practices.

The following standards are supported by Monkey365:

* CIS Microsoft Azure Foundations Benchmark v3.0.0
* CIS Microsoft 365 Foundations Benchmark v3.0.0 and v4.0.0

More standards will be added in next releases (NIST, HIPAA, GDPR, PCI-DSS, etc..) as they are available.

# Notes about security controls

For each standard, and depending on the environment, there is a list of applicable controls. Depending on the standard, some checks may be procedure, or process related best-practices, so this can't be verified by Monkey365. Some of them don't have any rule implemented yet, but will have in the future.