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

Function Get-MonkeyAzAppServiceEnvironmentInfo {
    <#
        .SYNOPSIS
		Get Azure app service environment metadata

        .DESCRIPTION
		Get Azure app service environment metadata

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAppServiceEnvironmentInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-03-01"
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
        try{
            $msg = @{
				MessageData = ($message.AzureUnitResourceMessage -f $InputObject.Name,"Azure App Service Environment");
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureAppServiceEnvironmentInfo');
			}
			Write-Information @msg
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $appEnvironment = Get-MonkeyAzObjectById @p
            if($null -ne $appEnvironment){
                $appServiceObj = $appEnvironment | New-MonkeyAppServiceEnvironmentObject
                #Get Locks
                $appServiceObj.locks = $appServiceObj | Get-MonkeyAzLockInfo
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $appServiceObj.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $appServiceObj.diagnosticSettings.enabled = $true;
                        $appServiceObj.diagnosticSettings.name = $diag.name;
                        $appServiceObj.diagnosticSettings.id = $diag.id;
                        $appServiceObj.diagnosticSettings.properties = $diag.properties;
                        $appServiceObj.diagnosticSettings.rawData = $diag;
                    }
                    #Get SSL Settings
                    $appServiceObj.clusterSettings.DisableTls1 = $appServiceObj | Get-MonkeyAzAppEnvironmentClusterObjectProperty -Property "DisableTls1.0"
                    $appServiceObj.clusterSettings.internalEncryption = $appServiceObj | Get-MonkeyAzAppEnvironmentClusterObjectProperty -Property "InternalEncryption"
                    $appServiceObj.clusterSettings.frontEndSSLCipherSuiteOrder = $appServiceObj | Get-MonkeyAzAppEnvironmentClusterObjectProperty -Property "FrontEndSSLCipherSuiteOrder"
                    $appServiceObj.clusterSettings.linuxFipsModeEnabled = $appServiceObj | Get-MonkeyAzAppEnvironmentClusterObjectProperty -Property "LinuxFipsModeEnabled"
                }
                #Return object
                return $appServiceObj
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
