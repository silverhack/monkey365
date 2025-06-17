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

Function Get-MonkeyMSGraphPIMRoleManagementPolicy {
    <#
        .SYNOPSIS
		Get the details of the policies in PIM that can be applied to Microsoft Entra roles or group membership or ownership

        .DESCRIPTION
		Get the details of the policies in PIM that can be applied to Microsoft Entra roles or group membership or ownership

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphPIMRoleManagementPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'PolicyId', ValueFromPipeline = $True, HelpMessage="Policy Id")]
        [String]$InputObject,

        [Parameter(Mandatory=$false, ParameterSetName = 'DirectoryRole', HelpMessage="Roles scoped to the tenant")]
        [Switch]$DirectoryRole,

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
        if($PSCmdlet.ParameterSetName -eq 'PolicyId'){
            $p = @{
                Authentication = $graphAuth;
                ObjectType = ('policies/roleManagementPolicies/{0}/rules' -f $PSBoundParameters['InputObject']);
                Environment = $Environment;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphObject @p
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'DirectoryRole'){
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'policies/roleManagementPolicies';
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
        Else{
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'policies/roleManagementPolicies';
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphObject @p
        }
    }
    End{
        #Nothing to do here
    }
}
