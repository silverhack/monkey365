---
author: Juan Garrido
---

# Monkey365
![](assets/images/monkey365.png)

Monkey365 is an Open Source security tool that can be used to easily conduct not only Microsoft 365, but also Azure subscriptions and Azure Active Directory security configuration reviews without the significant overhead of learning tool APIs or complex admin panels from the start.

Monkey365 has been designed to tackle these difficulties and get results fast and without any requirements. The results will be visualised in a simplified HTML report to quickly identify potential issues. As such, security consultants will be able to effectively address issues from a 
single vulnerability report.

![](../assets/images/htmlreport.png)

To help with this effort, Monkey365 also provides several ways to identify security gaps in the desired tenant setup and configuration. Monkey365 provides valuable recommendations on how to best configure those settings to get the most out of your Microsoft 365 tenant or Azure subscription.

# Architecture

Monkey365 works in two phases. In the first phase, plugins will issue queries against the multiple data sources to retrieve metadata about targeted tenant or subscription, and then will collect information. Once all the necessary data is collected, the result is passed to the verifying phase, in which the tool uses the data collected in first phase to perform static analysis and query search, as a mechanism to evaluate the configuration and to search for potential misconfigurations and security issues.