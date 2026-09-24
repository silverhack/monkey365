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

Function Get-MonkeyMSGraphSignInLog {
    <#
        .SYNOPSIS
		Get Microsoft Entra user sign-ins for a tenant

        .DESCRIPTION
		Get Microsoft Entra user sign-ins for a tenant

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphSignInLog
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("24H","7Days","lastMonth")]
        [String]$DataRange = "24H",

        [parameter(Mandatory=$False, HelpMessage='Non Interactive')]
        [Switch]$NonInteractive,

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
                $Filter = ("createdDateTime ge {0} and createdDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            '7Days'
            {
                $Filter = ("createdDateTime ge {0} and createdDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            'lastMonth'
            {
                $Filter = ("createdDateTime ge {0} and createdDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
            Default
            {
                $Filter = ("createdDateTime ge {0} and createdDateTime lt {1}" -f [System.DateTime]::UtcNow.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ss.fff"+"Z"),$now)
            }
        }
        #Check if non interactive
        If($NonInteractive.IsPresent){
            $Filter = ("(signInEventTypes/any(t: t eq 'nonInteractiveUser')) and {1}" -f $Filter)
        }
    }
    Process{
        If($NonInteractive.IsPresent){
            #We need to switch to beta endpoint
            $APIVersion = 'beta';
        }
        $p = @{
            Authentication = $graphAuth;
            ObjectType = 'auditLogs';
            ObjectId = 'signIns';
            Filter = $Filter;
            OrderBy = $OrderBy;
            Source = 'kds';
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