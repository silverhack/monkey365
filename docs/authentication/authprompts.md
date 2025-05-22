---
author: Juan Garrido
---

## Well Known Microsoft's applications

Monkey365 requires the use of first-party Microsoft registered applications to connect to Microsoft 365 services when [Interactive browser authentication](authFlows/interactive.md) or [Device Code Authentication](authFlows/devicecode.md) method is used.

## Multiple authentication prompts

You may receive multiple authentication prompts depending on:

* When multiple services are selected within the -Collect flag

* If a conditional access policy is configured to require an extra multi-factor authentication

The authentication prompt experience that you can expect is described in the following table:

<center>
<table>
  <thead>
    <tr>
      <th>Service</th>
	  <th>Authentication Prompts</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Exchange Online and Purview</td>
      <td>Single prompt</td>
    </tr>
    <tr>
      <td>SharePoint Online</td>
      <td>Single prompt</td>
    </tr>
	<tr>
      <td>Microsoft Graph</td>
      <td>Single prompt</td>
    </tr>
	<tr>
      <td>Microsoft GraphV2</td>
      <td>Single prompt</td>
    </tr>
	<tr>
      <td>Azure</td>
      <td>Single prompt</td>
    </tr>
  </tbody>
</table>
</center>

That means that if a user is selecting for example Exchange Online, Purview and SharePoint Online in the `-Collect` flag, the user will see multiple authentication prompts. New authentication prompt is needed when the application has its own OAuth Refresh Token and is not shared with other client apps. 