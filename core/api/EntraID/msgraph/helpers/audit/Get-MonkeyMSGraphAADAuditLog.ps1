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

Function Get-MonkeyMSGraphAADAuditLog {
    <#
        .SYNOPSIS
		Get Audit logs from Azure AD

        .DESCRIPTION
		Get Audit logs from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADAuditLog
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory = $false,HelpMessage = "Days ago")]
		[Int32]$Days = 15,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        #Set Days ago
        $DaysAgo = "{0:s}" -f (Get-Date).AddDays($Days) + "Z"
        if($null -ne (Get-Variable -Name O365Object -ErrorAction SilentlyContinue)){
            try{
                $AADConfig = $O365Object.internal_config.entraId
                $DaysAgo = "{0:s}" -f (Get-Date).AddDays($AADConfig.auditLog.AuditLogDaysAgo) + "Z"
            }
            catch{
                $DaysAgo = "{0:s}" -f (Get-Date).AddDays(-15) + "Z"
            }
        }
        elseif($PSBoundParameters.ContainsKey('Days') -and $PSBoundParameters.Days){
             $DaysAgo = "{0:s}" -f (Get-Date).AddDays($PSBoundParameters.Days) + "Z"
        }
        #Set filter
        $Filter = 'activityDateTime gt {0}' -f $DaysAgo
    }
    Process{
        $params = @{
            Authentication = $GraphAuth;
	        ObjectType = "auditLogs/directoryaudits";
	        Environment = $Environment;
	        ContentType = 'application/json';
            Filter = $Filter;
	        Method = "GET";
            APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyMSGraphObject @params
    }
    End{
        #Nothing to do here
    }
}
