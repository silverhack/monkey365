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

Function Get-MonkeyMSGraphAADServicePrincipal {
<#
        .SYNOPSIS
		Plugin to get azure service principal from Azure AD

        .DESCRIPTION
		Plugin to get azure service principal from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADServicePrincipal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'ServicePrincipalId', ValueFromPipeline = $True)]
        [String]$ServicePrincipalId,

        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [String]$Expand,

        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [String]$ElementType,

        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
        [String]$Filter,

        [Parameter(Mandatory=$false, ValueFromPipeline = $True)]
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
        if($PSCmdlet.ParameterSetName -eq 'ServicePrincipalId'){
            $msg = @{
			    MessageData = ($message.AzureADServicePrincipalInfo -f $ServicePrincipalId);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('AzureADServicePrincipalInfo');
		    }
		    Write-Information @msg
            if($ElementType){
                $objectType = ('servicePrincipals/{0}/{1}' -f $ServicePrincipalId,$ElementType)
            }
            else{
                $objectType = ('servicePrincipals/{0}' -f $ServicePrincipalId)
            }
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
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
            $servicePrincipal = Get-MonkeyMSGraphObject @params
        }
        else{
            $msg = @{
			    MessageData = ($message.AzureADServicePrincipalAllInfo);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AzureADServicePrincipalInfo');
		    }
		    Write-Information @msg
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'servicePrincipals';
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
            $servicePrincipal = Get-MonkeyMSGraphObject @params
        }
        #Return service principal
        if($servicePrincipal){
            $servicePrincipal
        }
    }
    End{
        #Nothing to do here
    }
}