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

Function Get-MonkeyMSGraphAppManagementPolicy {
<#
        .SYNOPSIS
		Get the app management policies created for applications and service principals along with their properties

        .DESCRIPTION
		Get the app management policies created for applications and service principals along with their properties

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAppManagementPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false,ValueFromPipeline = $True, ParameterSetName = 'PolicyId', HelpMessage="Policy Id")]
        [String]$PolicyId,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "beta"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'AppId'){
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'policies/appManagementPolicies';
                ObjectId = $PolicyId;
                Environment = $Environment;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        Else{
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'policies/appManagementPolicies';
                Environment = $Environment;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        #Execute query
        Get-MonkeyMSGraphObject @p
    }
}
