---
author: Juan Garrido
---
Monkey365 offers many ways to connect to both Azure and Microsoft 365 environments. This section covers the authentication process against Azure or Microsoft 365, as well as the supported authentication options, including:

* Interactive browser authentication
* Authentication with a username and password
* Device Code Authentication
* Client Credential Authentication

## Interactive browser authentication

Interactive browser authentication enables the monkey 365 PowerShell module for all operations allowed by the interactive login credentials. Please, note that if you are using a user with owner or administrator permissions within the subscription in scope, the monkey365 tool will inherent these permissions to all resources in that subscription without having to assign any specific permissions. Please, see the [permissions](permissions.md) for further details.

## Resource Owner Password Credentials

The Microsoft identity platform supports the OAuth 2.0 Resource Owner Password Credentials (ROPC) grant, which allows an application to sign in the user by directly handling their password. In this flow, client identification (e.g. user's email address) and user's credentials is sent to the identity server, and then a token is received.

## Device code authentication

Interactive authentication with Microsoft Entra ID requires a web browser. However, in operating systems that do not provide a Web browser, such as containers, command line tools or non-gui systems, Device code flow lets the user use another computer to sign-in interactively. The tokens will be obtained through a two-step process.

## Client credential authentication

This type of grant is commonly used for machine-to-machine interactions that must run in the background, such as daemons, or service accounts. In this case, Microsoft Entra ID authenticates and authorizes the app rather than a user. During this step, the client has to authenticate itself to Microsoft Entra ID. The Microsoft identity platform allows the confidential client to authenticate using a shared secret, certificate or federated credential.

