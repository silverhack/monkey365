---
author: Juan Garrido
---

# Overview

Monkey365 helps streamline the process of performing not only Microsoft 365, but also Azure subscriptions and Microsoft Entra ID Security Reviews.

160+ checks covering industry defined security best practices for Microsoft 365, Azure and Microsoft Entra ID.

All rulesets are located at ```$monkey365_DIR/rules/ruleset``` directory.

Monkey365 will help consultants to assess cloud environment and to analyze the risk factors according to controls and best practices. The report will contain structured data for quick checking and verification of the results.

# Supported standards

By default, the HTML report shows you the CIS (Center for Internet Security) Benchmark. The CIS Benchmarks for Azure and Microsoft 365 are guidelines for security and compliance best practices.

The following standards are supported by Monkey365:

* CIS Microsoft Azure Foundations Benchmark v1.4.0, v1.5.0
* CIS Microsoft 365 Foundations Benchmark v1.4.0, v1.5.0

More standards will be added in next releases (NIST, HIPAA, GDPR, PCI-DSS, etc..) as they are available.

# Notes about security controls

For each standard, and depending on the environment, there is a list of applicable controls. Depending on the standard, some checks may be procedure, or process related best-practices, so this can't be verified by Monkey365. Some of them don't have any rule implemented yet, but will have in the future.