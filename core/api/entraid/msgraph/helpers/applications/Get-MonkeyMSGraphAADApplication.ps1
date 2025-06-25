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

Function Get-MonkeyMSGraphAADApplication {
<#
        .SYNOPSIS
		Plugin to get azure apps from Azure AD

        .DESCRIPTION
		Plugin to get azure apps from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADApplication
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'ApplicationId', ValueFromPipeline = $True)]
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
        if($PSCmdlet.ParameterSetName -eq 'ApplicationId'){
            $msg = @{
			    MessageData = ($message.EntraIDApplicationInfo -f $ApplicationId);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationInfo');
		    }
		    Write-Information @msg
            $objectType = ('applications/{0}' -f $ApplicationId)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                Filter = $Filter;
                Expand = $Expand;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $application = Get-MonkeyMSGraphObject @params
        }
        else{
            $msg = @{
			    MessageData = ($message.EntraIDApplicationAllInfo);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDApplicationInfo');
		    }
		    Write-Information @msg
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'applications';
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                Filter = $Filter;
                Expand = $Expand;
                Count = $Count;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $application = Get-MonkeyMSGraphObject @params
        }
        #return app
        if($application){
            $application
        }
    }
}
