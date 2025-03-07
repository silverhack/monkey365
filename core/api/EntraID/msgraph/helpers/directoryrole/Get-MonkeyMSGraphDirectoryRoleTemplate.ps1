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

Function Get-MonkeyMSGraphDirectoryRoleTemplate {
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

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'TemplateId', ValueFromPipeline = $True, HelpMessage="Template Id")]
        [String]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'TemplateId'){
            $p = @{
                Authentication = $graphAuth;
                ObjectType = ('directoryRoleTemplates/{0}' -f $PSBoundParameters['InputObject']);
                Environment = $Environment;
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
                ObjectType = 'directoryRoleTemplates';
                Environment = $Environment;
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

