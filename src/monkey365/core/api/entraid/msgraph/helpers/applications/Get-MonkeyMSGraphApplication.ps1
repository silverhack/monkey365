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

Function Get-MonkeyMSGraphApplication {
<#
        .SYNOPSIS
		Plugin to get azure apps from Entra ID

        .DESCRIPTION
		Plugin to get azure apps from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphApplication
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'ApplicationId', ValueFromPipeline = $True)]
        [String]$ApplicationId,

        [Parameter(Mandatory=$false)]
        [String]$Expand,

        [Parameter(Mandatory=$false)]
        [String]$Filter,

        [Parameter(Mandatory=$false)]
        [Switch]$Count,

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
        If($PSCmdlet.ParameterSetName -eq 'ApplicationId'){
            $msg = @{
			    MessageData = ($message.EntraIDApplicationInfo -f $ApplicationId);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationInfo');
		    }
		    Write-Information @msg
            #Set param
            $p = @{
                Authentication = $graphAuth;
                ObjectType = ('applications/{0}' -f $ApplicationId);
                Environment = $Environment;
                Method = "GET";
                Filter = $Filter;
                Expand = $Expand;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        Else{
            $msg = @{
			    MessageData = ($message.EntraIDApplicationAllInfo);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationInfo');
		    }
		    Write-Information @msg
            #Set param
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'applications';
                Environment = $Environment;
                Method = "GET";
                Filter = $Filter;
                Expand = $Expand;
                Count = $Count;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        #Execute command
        Get-MonkeyMSGraphObject @p
    }
}
