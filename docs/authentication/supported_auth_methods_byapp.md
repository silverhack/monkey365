---
author: Juan Garrido
---

# Supported authentication methods by Service

The following table shows the supported authentication methods for each type of service.

## Windows Environments

<table>
  <thead>
    <tr>
      <th>Authentication method</th>
	  <th>Azure AD Portal</th>
	  <th>Azure AD GraphV2</th>
	  <th>Azure services</th>
	  <th>Exchange Online</th>
	  <th>Purview</th>
	  <th>SharePoint Online</th>
	  <th>Microsoft Teams</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Interactive browser authentication</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
    <tr>
      <td>Device code authentication</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
	<tr>
      <td>Service Principal Authentication (Client Secret)</td>
      <td>❌️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>❌</td>
      <td>❌️</td>
	  <td>❌️</td>
      <td>❌</td>
    </tr>
	<tr>
      <td>Service Principal Authentication (Certificate Secret)</td>
      <td>❌️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
	<tr>
      <td>Resource Owner Password Credentials</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
  </tbody>
</table>

## NIX Environments (.NET Core)

<table>
  <thead>
    <tr>
      <th>Authentication method</th>
	  <th>Azure AD Portal</th>
	  <th>Azure AD GraphV2</th>
	  <th>Azure services</th>
	  <th>Exchange Online</th>
	  <th>Purview</th>
	  <th>SharePoint Online</th>
	  <th>Microsoft Teams</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Interactive browser authentication</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️*</td>
	  <td>❌*</td>
      <td>✔️</td>
    </tr>
    <tr>
      <td>Device code authentication</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
	<tr>
      <td>Service Principal Authentication (Client Secret)</td>
      <td>❌️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>❌</td>
      <td>❌️</td>
	  <td>❌️</td>
      <td>❌</td>
    </tr>
	<tr>
      <td>Service Principal Authentication (Certificate Secret)</td>
      <td>❌️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
    </tr>
	<tr>
      <td>Resource Owner Password Credentials</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>✔️</td>
      <td>✔️</td>
	  <td>❌*</td>
      <td>✔️</td>
    </tr>
  </tbody>
</table>