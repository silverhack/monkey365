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

Function Get-MonkeyAzSubscriptionInfo {
    <#
        .SYNOPSIS
		Get subscription metadata from Azure

        .DESCRIPTION
		Get subscription metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSubscriptionInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject
    )
    Process{
        Try{
            #Get storage account config
            $strConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.displayName,"Azure Subscription");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionInfo');
			}
			Write-Information @msg
            #copy object
            $_subscription = $InputObject | New-MonkeySubscriptionObject
            If($_subscription){
                #Get diagnostic settings
                $p = @{
		            Id = $_subscription.Id;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $diag = Get-MonkeyAzDiagnosticSettingsById @p
                If($diag){
                    ForEach($diagnostic in @($diag)){
                        #Create object
                        $diagnosticSettings = $_subscription.newDiagnosticObject()
                        #Add to object
                        $diagnosticSettings.enabled = $true;
                        $diagnosticSettings.name = $diagnostic.name;
                        $diagnosticSettings.id = $diagnostic.id;
                        $diagnosticSettings.properties = $diagnostic.properties;
                        $diagnosticSettings.rawData = $diagnostic;
                        #Get storage account Id
                        $strAccount = $diagnosticSettings.properties | Select-Object -ExpandProperty storageAccountId -ErrorAction Ignore
                        If($strAccount){
                            $p = @{
			                    Id = $strAccount;
                                ApiVersion = $strConfig.api_version;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
		                    }
		                    $strObject = Get-MonkeyAzObjectById @p | Get-MonkeyAzStorageAccountInfo
                            If($strObject){
                                $diagnosticSettings.storageAccount = $strObject
                            }
                        }
                        #Add diagnostic settings
                        $_subscription.diagnosticSettings.Add($diagnosticSettings);
                    }
                }
                return $_subscription
            }

        }
        Catch{
            Write-Verbose $_
        }
    }
    End{
        #nothing to do here
    }
}

