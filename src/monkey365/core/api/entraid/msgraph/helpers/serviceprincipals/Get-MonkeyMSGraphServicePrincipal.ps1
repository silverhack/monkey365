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

Function Get-MonkeyMSGraphServicePrincipal {
<#
        .SYNOPSIS
		Plugin to get azure service principal from Entra ID

        .DESCRIPTION
		Plugin to get azure service principal from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphServicePrincipal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'ServicePrincipalId', ValueFromPipeline = $True)]
        [String]$ServicePrincipalId,

        [Parameter(Mandatory=$false, HelpMessage="Expand object")]
        [String]$Expand,

        [Parameter(Mandatory=$false, HelpMessage="Object Type")]
        [String]$ObjectType,

        [Parameter(Mandatory=$false, HelpMessage="Filter")]
        [String]$Filter,

        [parameter(Mandatory=$false, HelpMessage="Select object")]
        [String[]]$Select,

        [Parameter(Mandatory=$false, HelpMessage="Count")]
        [Switch]$Count,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'ServicePrincipalId'){
            $msg = @{
			    MessageData = ($message.EntraIDServicePrincipalInfo -f $ServicePrincipalId);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('EntraIDServicePrincipalInfo');
		    }
		    Write-Information @msg
            If($ObjectType){
                $ObjectType = ('servicePrincipals/{0}/{1}' -f $ServicePrincipalId,$ObjectType)
            }
            Else{
                $ObjectType = ('servicePrincipals/{0}' -f $ServicePrincipalId)
            }
            $p = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                Filter = $Filter;
                Select = $Select;
                Expand = $Expand;
                Count = $Count;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        Else{
            $msg = @{
			    MessageData = ($message.EntraIDServicePrincipalAllInfo);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('EntraIDServicePrincipalInfo');
		    }
		    Write-Information @msg
            $p = @{
                Authentication = $graphAuth;
                ObjectType = 'servicePrincipals';
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                Filter = $Filter;
                Select = $Select;
                Expand = $Expand;
                Count = $Count;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        #Execute query
        Get-MonkeyMSGraphObject @p
    }
    End{
        #Nothing to do here
    }
}
