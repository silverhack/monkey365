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

Function Get-MonkeyMSGraphSummarizedSignInLog {
    <#
        .SYNOPSIS
		Get Microsoft Entra aggregated sign-in events

        .DESCRIPTION
		Get Microsoft Entra aggregated sign-in events

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphSummarizedSignInLog
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'NonIT')]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("24H","7Days","lastMonth")]
        [String]$DataRange = "24H",

        [Parameter(Mandatory=$false, ParameterSetName = 'NonIT', HelpMessage="Non Interactive Sign-In")]
        [Switch]$NonInteractive,

        [Parameter(Mandatory=$false, ParameterSetName = 'SP', HelpMessage="Service Principal Sign-In")]
        [Switch]$ServicePrincipal,

        [Parameter(Mandatory=$false, ParameterSetName = 'MI', HelpMessage="Managed Identity Sign-In")]
        [Switch]$ManagedIdentity,

        [parameter(Mandatory=$false, HelpMessage="Order By")]
        [String]$OrderBy,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        #Now
        $now = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z")
        #Get Date
        Switch($DataRange.ToLower()){
            '24h'
            {
                $Filter = ("firstSignInDateTime ge {0} and firstSignInDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            '7Days'
            {
                $Filter = ("firstSignInDateTime ge {0} and firstSignInDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            'lastMonth'
            {
                $Filter = ("firstSignInDateTime ge {0} and firstSignInDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            Default
            {
                $Filter = ("firstSignInDateTime ge {0} and firstSignInDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
        }
        #Check Log type
        Switch($PSCmdlet.ParameterSetName.ToLower()){
            'nonit'
            {
                $ObjectId = "getSummarizedNonInteractiveSignIns(aggregationWindow='h1')";
            }
            'sp'
            {
                $ObjectId = "getSummarizedServicePrincipalSignIns(aggregationWindow='h1')";
            }
            'msi'
            {
                $ObjectId = "getSummarizedMSISignIns(aggregationWindow='h1')";
            }
        }
    }
    Process{
        If($APIVersion.ToLower() -eq 'v1.0'){
            #We need to switch to beta endpoint
            $APIVersion = 'beta';
        }
        $p = @{
            Authentication = $graphAuth;
            ObjectType = 'auditLogs';
            ObjectId = $ObjectId;
            Filter = $Filter;
            Source = 'kds';
            OrderBy = $OrderBy;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #execute command
        Get-MonkeyMSGraphObject @p
    }
}
