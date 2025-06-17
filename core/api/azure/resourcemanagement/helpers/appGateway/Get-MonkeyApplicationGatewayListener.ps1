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

Function Get-MonkeyApplicationGatewayListener {
    <#
        .SYNOPSIS
		Get Application gateway listeners

        .DESCRIPTION
		Get Application gateway listeners

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyApplicationGatewayListener
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-06-01"
    )
    Process{
        try{
            $p = @{
                Environment = $O365Object.Environment;
                Provider = 'Microsoft.Network';
                ObjectType = "applicationGatewayAvailableSslOptions/default";
                ApiVersion = $APIVersion;
                Authentication = $O365Object.auth_tokens.ResourceManager;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            Get-MonkeyRMObject @p
        }
        catch{
            Write-Verbose $_
        }
    }
}
