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

Function Get-MonkeyAzStorageManagedLustreInfo {
    <#
        .SYNOPSIS
		Get information about storage Managed Lustre resource from Azure

        .DESCRIPTION
		Get information about storage Managed Lustre resource from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageManagedLustreInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2026-01-01"
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
                $lustreObject = $obj | New-MonkeyStorageManagedLustreObject
                #Get Import jobs
                $p = @{
			        Id = ("{0}/importJobs" -f $InputObject.Id);
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $lustreObject.importJobs = Get-MonkeyAzObjectById @p
                #Get Auto export jobs
                $p = @{
			        Id = ("{0}/autoExportJobs" -f $InputObject.Id);
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
		        $lustreObject.autoExportJobs = Get-MonkeyAzObjectById @p
                #Get locks
                $lustreObject.locks = $lustreObject | Get-MonkeyAzLockInfo
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $InputObject.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $lustreObject.diagnosticSettings.enabled = $true;
                        $lustreObject.diagnosticSettings.name = $diag.name;
                        $lustreObject.diagnosticSettings.id = $diag.id;
                        $lustreObject.diagnosticSettings.properties = $diag.properties;
                        $lustreObject.diagnosticSettings.rawData = $diag;
                    }
                }
                return $lustreObject
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
