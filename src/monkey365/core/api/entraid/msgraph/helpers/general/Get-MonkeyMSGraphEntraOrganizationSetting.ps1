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

Function Get-MonkeyMSGraphEntraOrganizationSetting {
    <#
        .SYNOPSIS
		Get Entra ID organization settings from Microsoft Graph

        .DESCRIPTION
		Get Entra ID organization settings from Microsoft Graph

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphEntraOrganizationSetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $false, HelpMessage= "Select an Entra ID Policy")]
        [ValidateSet("adminForms","todo","dynamics","appsAndServices","uxSetting"
        )]
        [String]$Setting= "adminForms",

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
        Switch($Setting.ToLower()){
            'adminForms'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'forms';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'todo'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'todo';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'dynamics'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'dynamics';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'appsAndServices'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'appsAndServices';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            'uxSetting'{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'entra/uxSetting';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            default{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'admin';
                    ObjectId = 'forms';
                    Environment = $Environment;
                    Method = "GET";
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
        }
        Get-MonkeyMSGraphObject @p
    }
    End{
        #Nothing to do here
    }
}
