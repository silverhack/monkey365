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

Function Get-MonkeyAzPrivateEndpoint {
    <#
        .SYNOPSIS
		Get private endpoints

        .DESCRIPTION
		Get private endpoints. Filter by subscription or resource group or Id

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPrivateEndpoint
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'subscription')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'resource', HelpMessage="Resource Group")]
        [System.String]$ResourceGroup,

        [Parameter(Mandatory=$false, ParameterSetName = 'id', HelpMessage="Resource Id")]
        [System.String]$Id,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-05-01"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Azure Auth
        $auth = $O365Object.auth_tokens.ResourceManager;
    }
    Process{
        try{
            If($PSCmdlet.ParameterSetName -eq 'resource'){
                $p = @{
                    Authentication = $auth;
                    Environment = $Environment;
                    Provider = 'Microsoft.Network';
                    ObjectType = "privateEndpoints";
                    ResourceGroup = $ResourceGroup;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                Get-MonkeyRMObject @p
            }
            ElseIf($PSCmdlet.ParameterSetName -eq 'Id'){
                $p = @{
			        Id = $Id;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        Get-MonkeyAzObjectById @p
            }
            Else{
                $p = @{
                    Authentication = $auth;
                    Environment = $Environment;
                    Provider = 'Microsoft.Network';
                    ObjectType = "privateEndpoints";
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                Get-MonkeyRMObject @p
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
