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

Function Get-MonkeyAzRedisPrivateEndpoint {
    <#
        .SYNOPSIS
		Get Redis private endpoint

        .DESCRIPTION
		Get Redis private endpoint

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRedisPrivateEndpoint
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Redis object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-08-01-preview"
    )
    Process{
        #Set array
        $allPrivateEndpoints = [System.Collections.Generic.List[System.Object]]::new()
        Try{
            $private_endpoints = $InputObject.properties | Select-Object -ExpandProperty privateEndpointConnections -ErrorAction Ignore
            If($private_endpoints){
                ForEach($private_endpoint in @($private_endpoints)){
                    $privateEndpointObj = [PsCustomObject]@{
                        id = $private_endpoint | Select-Object -ExpandProperty id -ErrorAction Ignore;
                        name = $private_endpoint.id.Split('/')[-1];
                        type = "Microsoft.Cache/Redis/privateEndpointConnections";
                        properties = $private_endpoint | Select-Object -ExpandProperty properties -ErrorAction Ignore
                    }
                    [void]$allPrivateEndpoints.Add($privateEndpointObj);
                }
            }
            Else{
                #Get private endpoints
                $p = @{
			        Id = $InputObject.Id;
                    Resource = '/privateEndpointConnections';
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $private_endpoints = Get-MonkeyAzObjectById @p
                If($private_endpoints){
                    ForEach($privateEndpoint in @($private_endpoints)){
                        [void]$allPrivateEndpoints.Add($privateEndpoint);
                    }
                }
                Else{
                    $privateEndpointObj = [PsCustomObject]@{
                        id = $null
                        name = $null
                        type = "Microsoft.Cache/Redis/privateEndpointConnections";
                        properties = $null
                    }
                    [void]$allPrivateEndpoints.Add($privateEndpointObj);
                }
            }
        }
        Catch{
            Write-Verbose $_
        }
        #return Object
        Write-Output $allPrivateEndpoints -NoEnumerate
    }
}
