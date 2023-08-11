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

Function Get-MonkeyAzAPIManagementService {
    <#
        .SYNOPSIS
		Get Azure API Management Service

        .DESCRIPTION
		Get Azure API Management Service

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAPIManagementService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'Id')]
        [String]$Id,

        [Parameter(Mandatory=$false, ParameterSetName = 'APIM')]
        [Object]$APIManagementService,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-09-01-preview"
    )
    try{
        $apimObject = $null;
        if($PSCmdlet.ParameterSetName -eq 'Id'){
            $p = @{
			    Id = $Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $apimObject = Get-MonkeyAzObjectById @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'APIM'){
            $p = @{
			    Id = $APIManagementService.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $apimObject = Get-MonkeyAzObjectById @p
        }
        else{
            if(!$PSBoundParameters.ContainsKey('APIVersion')){
                #Get Config
                $apimConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "APIManagement" } | Select-Object -ExpandProperty resource
                $api_version = $apimConfig.api_version;
            }
            else{
                $api_version = $PSBoundParameters['APIVersion'];
            }
            $p = @{
                Id = ("subscriptions/{0}/providers/{1}" -f $O365Object.current_subscription.subscriptionId, $apimConfig.provider);
                Resource = 'service';
                ApiVersion = $api_version;
                Method = 'Get';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
		    $apimObject = Get-MonkeyAzObjectById @p
        }
        if($null -ne $apimObject){
            return $apimObject
        }
    }
    catch{
        Write-Verbose $_
    }
}