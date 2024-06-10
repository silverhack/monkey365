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
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="mailBox user")]
        [Object]$MailBox
    )
    Begin{
        #Getting environment
        $Environment = $O365Object.Environment
        #Get Exo authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
    }
    Process{
        $msg = @{
			MessageData = ($message.ExoMailBoxPermissionInfo -f $MailBox.Identity);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'verbose';
			InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
			Tags = @('ExoMailboxPermissionInfo');
		}
		Write-Verbose @msg
        #Get mailbox permission
        $param = @{
	        Authentication = $exo_auth;
	        Environment = $Environment;
	        ResponseFormat = 'clixml';
	        Command = ('Get-MailboxPermission -Identity {0}' -f $MailBox.Identity);
	        Method = "POST";
	        InformationAction = $O365Object.InformationAction;
	        Verbose = $O365Object.Verbose;
	        Debug = $O365Object.Debug;
        }
        $mbox_perm = Get-PSExoAdminApiObject @param
        $mbox_perm = @($mbox_perm).Where({($_.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY*" -or $_.User -match "S-1-5-21")})
        if($mbox_perm.Count -gt 0){
            $mbox_perm | Select-Object @{Name='mailBox';Expression={$_.Identity}},@{Name='userPrincipalName';Expression={$MailBox.userPrincipalName}}, @{Name='MailBoxType';Expression={$MailBox.RecipientTypeDetails}}, @{Name='AssignedTo';Expression={$_.User}},@{Name='AccessRights';Expression={$_.AccessRights.ToArray()}}
        }
    }
    End{
        Start-Sleep -Milliseconds 100
    }
}