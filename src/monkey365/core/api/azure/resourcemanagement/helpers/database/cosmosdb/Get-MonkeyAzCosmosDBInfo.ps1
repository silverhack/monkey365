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

Function Get-MonkeyAzCosmosDBInfo {
    <#
        .SYNOPSIS
		Get information about CosmosDB resource from Azure

        .DESCRIPTION
		Get information about CosmosDB resource from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzCosmosDBInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-11-01-preview"
    )
    Begin{
        $config = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq "DiagnosticSettings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($config){
            $diag_settings_api_Version = $config.api_version;
        }
        Else{
            #Fallback
            $diag_settings_api_Version = "2021-05-01-preview"
        }
    }
    Process{
        Try{
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $obj = Get-MonkeyAzObjectById @p
            If($obj){
                $cosmosDBObject = $obj | New-MonkeyCosmosDBObject
                #Update key format
                $cosmosDBObject = $cosmosDBObject | Format-CosmosDBKey
                # Get databases
                $cosmosDBObject.sqlDatabases = $cosmosDBObject | Get-MonkeyAzCosmosDBSQLDatabase
                #Get network SecurityPerimeter Configurations
                $p = @{
			        Id = $cosmosDBObject.Id;
                    Resource = "networkSecurityPerimeterConfigurations";
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $cosmosDBObject.networking.networkSecurityPerimeterConfigurations = Get-MonkeyAzObjectById @p
                # Get Private Endpoint connections
                $p = @{
					InputObject = $cosmosDBObject;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
		        $cosmosDBObject.networking.privateEndpointConnections = Get-MonkeyAzGenericPrivateEndpoint @p
                # Get Private Link Resources
                $p = @{
			        Id = $cosmosDBObject.Id;
                    Resource = "privateLinkResources";
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $cosmosDBObject.networking.privateLinkResources = Get-MonkeyAzObjectById @p
                #Get locks
                $cosmosDBObject.locks = $cosmosDBObject | Get-MonkeyAzLockInfo
                #Get sql role assignment
                $cosmosDBObject.sqlRoleAssignments = $cosmosDBObject | Get-MonkeyAzCosmosDBRoleAssignment
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $cosmosDBObject.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $cosmosDBObject.diagnosticSettings.enabled = $true;
                        $cosmosDBObject.diagnosticSettings.name = $diag.name;
                        $cosmosDBObject.diagnosticSettings.id = $diag.id;
                        $cosmosDBObject.diagnosticSettings.properties = $diag.properties;
                        $cosmosDBObject.diagnosticSettings.rawData = $diag;
                    }
                }
                return $cosmosDBObject
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
