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

Function Get-MonkeyMSGraphApplicationManagementPolicy {
    <#
        .SYNOPSIS
		Function to get managed policies for an Entra application

        .DESCRIPTION
		Function to get managed policies for an Entra application

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphApplicationManagementPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Application")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Add policy array to application")]
        [Switch]$AddToObject,

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        Try{
            #Set array
            $all_policies = [System.Collections.Generic.List[System.Object]]::new()
            $p = @{
                Authentication = $graphAuth;
                ObjectType = ('applications/{0}' -f $InputObject.id);
                ObjectId = 'appManagementPolicies';
                Environment = $Environment;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $policies = Get-MonkeyMSGraphObject @p
            ForEach($policy in @($policies).Where({$null -ne $_})){
                [void]$all_policies.Add($policy);
            }
            #Return object
            If($AddToObject.IsPresent){
                $InputObject | Add-Member -MemberType NoteProperty -Name appManagementPolicies -Value $all_policies -Force
                return $InputObject
            }
            Else{
                Write-Output $all_policies -NoEnumerate
            }
        }
        Catch{
            $msg = @{
                MessageData = ($message.GenericObjectErrorMessage -f "get application's management policies",$InputObject.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('EntraIDApplicationError');
            }
            Write-Warning @msg
            Write-Error $_.Exception.Message
            $msg = @{
			    MessageData = ($_);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationError');
		    }
		    Write-Verbose @msg
        }
    }
}
