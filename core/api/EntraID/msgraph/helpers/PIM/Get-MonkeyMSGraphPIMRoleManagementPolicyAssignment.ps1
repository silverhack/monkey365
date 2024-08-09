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

Function Get-MonkeyMSGraphPIMRoleManagementPolicyAssignment {
    <#
        .SYNOPSIS
		Get the details of all role management policy assignments made in PIM for Microsoft Entra roles and PIM for groups.

        .DESCRIPTION
		Get the details of all role management policy assignments made in PIM for Microsoft Entra roles and PIM for groups.

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphPIMRoleManagementPolicyAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "beta"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        $p = @{
            Authentication = $graphAuth;
            ObjectType = 'policies/roleManagementPolicyAssignments';
            Environment = $Environment;
            Filter = "scopeId eq '/' and scopeType eq 'DirectoryRole'";
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyMSGraphObject @p
    }
    End{
        #Nothing to do here
    }
}