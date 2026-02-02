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


Function Get-MonkeyMSGraphB2BLegacyPolicy{
    <#
        .SYNOPSIS
		Get B2BManagementPolicy legacy policies

        .DESCRIPTION
		Get B2BManagementPolicy legacy policies

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphB2BLegacyPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    try{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $p = @{
            Authentication = $graphAuth;
            ObjectType = "legacy/policies";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = 'beta';
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $policies = Get-MonkeyMSGraphObject @p
        ForEach($policy in @($policies)){
            $definition = $policy | Select-Object -ExpandProperty definition -ErrorAction Ignore
            If($null -ne $definition -and $definition -is [System.String]){
                #Try to convert to JSON
                Try{
                    $policy.definition = $policy.definition | ConvertFrom-Json
                }
                Catch{
                    Write-Warning "Unable to convert definition property to JSON"
                }
            }
        }
        return $policies
    }
    catch{
        $msg = @{
            MessageData = "Unable to get Entra ID B2BManagementPolicy legacy policies";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('AzureGraphAuthorizationPolicyError');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        [void]$msg.Add('verbose',$O365Object.verbose)
        Write-Verbose @msg
    }
}

