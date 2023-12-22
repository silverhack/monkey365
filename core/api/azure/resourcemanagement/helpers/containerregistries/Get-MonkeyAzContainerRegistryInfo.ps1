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

Function Get-MonkeyAzContainerRegistryInfo {
    <#
        .SYNOPSIS
		Get container registry metadata from Azure

        .DESCRIPTION
		Get container registry metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzContainerRegistryInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-02-01-preview"
    )
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $cr = Get-MonkeyAzObjectById @p
            if($cr){
                $newcrObject = New-MonkeyContainerRegistryObject -InputObject $cr
                if($newcrObject){
                    #Get Network properties
					if (-not $newcrObject.Properties.NetworkRuleSet) {
                        $newcrObject.allowAccessFromAllNetworks = $true
					}
					else {
						$newcrObject.allowAccessFromAllNetworks = $true
					}
                    #Get scopemap
                    $newcrObject.scopeMap = $newcrObject | Get-MonkeyContainerRegistryScopeMap
                    #Get registry tokens
                    $newcrObject.tokens = $newcrObject | Get-MonkeyContainerRegistryToken
                    #Get replication
                    $newcrObject.replication = $newcrObject | Get-MonkeyContainerRegistryReplication
                    #Get diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
		                    Id = $newcrObject.Id;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
	                    }
	                    $diag = Get-MonkeyAzDiagnosticSettingsById @p
                        if($diag){
                            #Add to object
                            $newcrObject.diagnosticSettings.enabled = $true;
                            $newcrObject.diagnosticSettings.name = $diag.name;
                            $newcrObject.diagnosticSettings.id = $diag.id;
                            $newcrObject.diagnosticSettings.properties = $diag.properties;
                            $newcrObject.diagnosticSettings.rawData = $diag;
                        }
                    }
                    #Get locks
                    $newcrObject.locks = $newcrObject | Get-MonkeyAzLockInfo
                    #return object
                    return $newcrObject
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}