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

Function Get-MonkeyMSGraphServicePrincipalSignInActivity {
<#
        .SYNOPSIS
		Get a list of objects that contains sign-in activity information for service principals in a Microsoft Entra tenant

        .DESCRIPTION
		Get a list of objects that contains sign-in activity information for service principals in a Microsoft Entra tenant

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphServicePrincipalSignInActivity
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'AppId', ValueFromPipeline = $True)]
        [String]$AppId,

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
                ObjectType = 'reports/servicePrincipalSignInActivities';
                Environment = $Environment;
                Method = "GET";
                Filter = ("appId eq '{0}'" -f $AppId);
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        Else{
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'reports/servicePrincipalSignInActivities';
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
