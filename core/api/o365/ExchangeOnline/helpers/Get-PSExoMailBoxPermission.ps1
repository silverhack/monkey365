# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function Get-PSExoMailBoxPermission{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoMailBoxPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$True, HelpMessage="mailBox user")]
        [object]$mailBox
    )
    Begin{
        $perm = $null
        #Getting environment
        $Environment = $O365Object.Environment
        #Get Exo authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
    }
    Process{
        #Get mailbox permission
        $uri = ("{0}/MailboxPermission" -f $mailBox.'@odata.id')
        $param = @{
            Authentication = $exo_auth;
            Environment = $Environment;
            OwnQuery = $uri;
            Method = "GET";
        }
        $mbox_perm = Get-PSExoAdminApiObject @param
        $mbox_perm = $mbox_perm | Where-Object {($_.PermissionList.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY*" -or $_.User -match "S-1-5-21")}
        if($mbox_perm){
            $perm = $mbox_perm | Select-Object @{Name='mailBox';Expression={$_.MailboxIdentity}},@{Name='userPrincipalName';Expression={$mailBox.userPrincipalName}}, @{Name='MailBoxType';Expression={$mailBox.RecipientTypeDetails}}, @{Name='AssignedTo';Expression={$_.user}},@{Name='AccessRights';Expression={[string]::join(', ', $_.PermissionList.AccessRights)}}
        }
    }
    End{
        if($perm){
            return $perm
        }
    }
}
