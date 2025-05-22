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

Function Get-MonkeyAzInsightActivityLogAlert {
    <#
        .SYNOPSIS
		Get activity log alerts from Azure insights

        .DESCRIPTION
		Get activity log alerts from Azure insights

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzInsightActivityLogAlert
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [int32]$Days
    )
    Begin{
        #Get current Date
        $current_date = [datetime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'azureInsights'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
        if($null -eq $apiDetails){
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        if($PSBoundParameters.ContainsKey('Days')){
            $_days = [datetime]::Now.AddDays($PSBoundParameters['Days']).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $tmp_filter = ("eventTimestamp ge \'{0}\' and eventTimestamp le \'{1}\'" -f $_days,$current_date)
            #Set filter
            $filter = [System.Text.RegularExpressions.Regex]::Unescape($tmp_filter)
        }
        else{
            $filter = $null;
        }
        if($null -ne $filter){
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                Environment = $O365Object.Environment;
                Provider = $apiDetails.provider;
                ObjectType = "activityLogAlerts";
                Filter = $filter;
                APIVersion= '2020-10-01';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            Get-MonkeyRMObject @p
        }
        else{
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                Environment = $O365Object.Environment;
                Provider = $apiDetails.provider;
                ObjectType = "activityLogAlerts";
                APIVersion= '2020-10-01';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            Get-MonkeyRMObject @p
        }
    }
    End{
        #nothing to do here
    }
}
