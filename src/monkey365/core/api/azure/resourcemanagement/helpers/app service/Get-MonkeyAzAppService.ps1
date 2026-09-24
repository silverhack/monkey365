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

Function Get-MonkeyAzAppService {
    <#
        .SYNOPSIS
		Get App Service from Azure

        .DESCRIPTION
		Get App Service from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAppService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-03-01"
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
	        $_obj = Get-MonkeyAzObjectById @p
            If($_obj){
                #Set new object
                $app_service = $_obj | New-MonkeyAppServiceObject
                #Get virtual network if any
                $vnetwork = $app_service.properties | Select-Object -ExpandProperty virtualNetworkSubnetId -ErrorAction Ignore
                If($null -ne $vnetwork){
                    $app_service.networking.subnet = $vnetwork;
                    #Get virtual network Id
                    $app_service.networking.virtualNetworkId = $vnetwork.Remove($vnetwork.LastIndexOf('/subnets/'))
                }
                #######Get Private Endpoint connections########
                $p = @{
					InputObject = $app_service;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$app_service.networking.privateEndpointConnections = Get-MonkeyAzGenericPrivateEndpoint @p
                #Get app configuration
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.config = Get-MonkeyAzAppServiceConfiguration @p
                If($null -ne $app_service.config){
                    #Get MinTls version
                    $app_service.networking.minimumTlsVersion = $app_service.config.properties | Select-Object -ExpandProperty minTlsVersion -ErrorAction Ignore
                }
                #Get app auth settings
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.authSettings = Get-MonkeyAzAppServiceAuthSetting @p
                #Get app auth settings V2
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.authSettingsV2 = Get-MonkeyAzAppServiceAuthSettingV2 @p
                #Get app settings
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.appSettings = Get-MonkeyAzAppServiceSetting @p
                #Get app hybrid connection relay
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.networking.hybridConnectionRelays = Get-MonkeyAzAppServiceHybridConnectionRelay @p
                #Get app virtual network connections
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.networking.virtualNetworkConnections = Get-MonkeyAzAppServiceVirtualNetworkConnection @p
                #Get app basic publishing credentials policies
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_service.basicPublishingCredentialsPolicies = Get-MonkeyAzAppServiceBasicPublishingCredentialsPolicy @p
                #Get app backup
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_backup = Get-MonkeyAzAppServiceBackup @p
                If($app_backup){
                    #Add to object
                    $app_service.recovery.backup.count = @($app_backup).Count;
                    $app_service.recovery.backup.rawData = $app_backup;
                }
                #Sleep to avoit Toomanyrequest issues
                Start-Sleep -Milliseconds 500
                #Get locks
                $app_service.locks = $app_service | Get-MonkeyAzLockInfo
                #Get app snapshot
                $p = @{
		            InputObject = $app_service;
                    ApiVersion = $APIVersion;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
	            }
	            $app_snapshot = Get-MonkeyAzAppServiceSnapShot @p
                if($app_snapshot){
                    #Add to object
                    $app_service.recovery.snapShot.count = @($app_snapshot).Count;
                    $app_service.recovery.snapShot.rawData = $app_snapshot;
                }
                #Sleep to avoit Toomanyrequest issues
                Start-Sleep -Milliseconds 500
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    #Get diagnostic settings
                    $p = @{
		                Id = $app_service.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $app_service.diagnosticSettings.enabled = $true;
                        $app_service.diagnosticSettings.name = $diag.name;
                        $app_service.diagnosticSettings.id = $diag.id;
                        $app_service.diagnosticSettings.properties = $diag.properties;
                        $app_service.diagnosticSettings.rawData = $diag;
                    }
                }
                #Check if identity is present
                If($null -ne $app_service.rawObject.PsObject.Properties.Item('identity')){
                    $app_service.identity.enabled = $true;
                    $app_service.identity.type = $app_service.rawObject.identity.type;
                    $app_service.identity.rawData = $app_service.rawObject.identity;
                }
                #Get Stack
                Try{
                    $linuxStack = $app_service.properties.siteConfig | Select-Object -ExpandProperty linuxFxVersion
                    If($null -ne $linuxStack -and $linuxStack.Length -gt 0){
                        $app_service.stack.operatingSystem = 'linux';
                        $runtime = $linuxStack.Split('|')[0]
                        $version = $linuxStack.Split('|')[1]
                        Switch($runtime.ToLower()){
                            'java'{
                                $app_service.stack.java.enabled = $true;
                                $app_service.stack.java.version = $version;
                            }
                            'php'{
                                $app_service.stack.php.enabled = $true;
                                $app_service.stack.php.version = $version;
                            }
                            'node'{
                                $app_service.stack.node.enabled = $true;
                                $app_service.stack.node.version = $version;
                            }
                            'python'{
                                $app_service.stack.python.enabled = $true;
                                $app_service.stack.python.version = $version;
                            }
                        }
                    }
                    Else{
                        #probably windows stack
                        $wStack = $app_service.config.properties | Select-Object -ExpandProperty windowsConfiguredStacks -ErrorAction Ignore
                        If($null -ne $wStack){
                            $app_service.stack.operatingSystem = 'windows';
                            $_stack = $wStack | Select-Object -ExpandProperty stack -ErrorAction Ignore
                            $_version = $wStack | Select-Object -ExpandProperty version -ErrorAction Ignore
                            If($null -ne $_stack -and $_stack.ToLower() -eq 'dotnet'){
                                $app_service.stack.dotnet.enabled = $true;
                                $app_service.stack.dotnet.version = $_version;
                            }
                        }
                    }
                }
                Catch{
                    Write-Warning ("Unable to get stack for {0}" -f $app_service.id)
                }
                #return app
                return $app_service
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
