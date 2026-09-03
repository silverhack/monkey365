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

Function Get-MonkeyAzSQlManagedInstanceServer {
    <#
        .SYNOPSIS
		Get SQL managed instance resource from Azure

        .DESCRIPTION
		Get SQL server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQlManagedInstanceServer
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
		    $dbServer = Get-MonkeyAzObjectById @p
            If($dbServer){
                $new_dbServer = $dbServer | New-MonkeyDatabaseServerObject
                #Get Encryption type if any
                $new_dbServer.encryption = $new_dbServer.properties | Select-Object -ExpandProperty keyId -ErrorAction Ignore
                # Get subnet if any
                $new_dbServer.networking.subnet = $new_dbServer.properties | Select-Object -ExpandProperty subnetId -ErrorAction Ignore
                #Get virtual network if any
                If($new_dbServer.networking.subnet){
                    $new_dbServer.networking.virtualNetworkId = $new_dbServer.networking.subnet.Remove($new_dbServer.networking.subnet.LastIndexOf('/subnets/'))
                }
                # Get databases
                $new_dbServer.databases = $new_dbServer | Get-MonkeyAzSQlManagedInstanceDatabase
                #Get Vulnerability config
                $p = @{
					Server = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.vaConfig = Get-MonkeyAzSQlVaConfig @p
                #######Get Server Threat Detection Policy########
                $p = @{
					Server = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$tdp = Get-MonkeyAzServerThreatDetectionPolicy @p
                If($tdp){
                    $new_dbServer.tdpSettings.enabled = $tdp.properties.state;
                    $new_dbServer.tdpSettings.disabledAlerts = $tdp.properties.disabledAlerts;
                    $new_dbServer.tdpSettings.emailAddresses = $tdp.properties.emailAddresses;
                    $new_dbServer.tdpSettings.sentToAdmins = $tdp.properties.emailAccountAdmins;
                    $new_dbServer.tdpSettings.retentionDays = $tdp.properties.retentionDays;
                    $new_dbServer.tdpSettings.rawData = $tdp;
                }
                #######Get SQL Server Transparent Data Encryption########
                $p = @{
					Server = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$tde = Get-MonkeyAzSQlServerEncryptorProtector @p
                If($tde){
                    $new_dbServer.tdeSettings.protectorMode = $tde.kind;
                    $new_dbServer.tdeSettings.properties.keyName = $tde.properties.serverKeyName;
                    $new_dbServer.tdeSettings.properties.keyType = $tde.properties.serverKeyType;
                    $new_dbServer.tdeSettings.properties.autoRotationEnabled = $tde.properties.autoRotationEnabled;
                    If($null -ne $tde.properties.PsObject.Properties.Item('uri')){
                        $new_dbServer.tdeSettings.protectorUri = $tde.Properties.uri;
                    }
                    $new_dbServer.tdeSettings.rawData = $tde;
                }
                #######Get Entra ID admin########
                $p = @{
					InputObject = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$aadAdmin = Get-MonkeyAzSQlServerAdmin @p
                If($aadAdmin){
                    $new_dbServer.sqlAd.enabled = $True;
                    $new_dbServer.sqlAd.type = $aadAdmin.properties.administratorType;
                    $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.login;
                    $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.sid;
                    $new_dbServer.sqlAd.login.tenantId = $aadAdmin.properties.tenantId;
                    $new_dbServer.sqlAd.login.azureADOnlyAuthentication = $aadAdmin.properties | Select-Object -ExpandProperty azureADOnlyAuthentication -ErrorAction Ignore
                    $new_dbServer.sqlAd.rawData = $aadAdmin;
                }
                #Get EntraID Only authentication
                $p = @{
					Server = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    EntraIDOnly = $True;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$onlyEid = Get-MonkeyAzSQlServerAdmin @p
                If($onlyEid){
                    $new_dbServer.sqlAd.entraIdOnlyAuthentication.rawData = $onlyEid
                    #Get Properties
                    $props = $onlyEid | Select-Object -ExpandProperty properties -ErrorAction Ignore
                    If($null -ne $props){
                        $new_dbServer.sqlAd.entraIdOnlyAuthentication.enabled = $props | Select-Object -ExpandProperty azureADOnlyAuthentication -ErrorAction Ignore
                    }
                    Else{
                        $new_dbServer.sqlAd.entraIdOnlyAuthentication.enabled = $false
                    }
                }
                Else{
                    $new_dbServer.sqlAd.entraIdOnlyAuthentication.enabled = $false
                }
                #######Get Private Endpoint connections########
                $p = @{
					Server = $new_dbServer;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.networking.privateEndpointConnections = Get-MonkeyAzSQLServerPrivateEndpointConnection @p
                #Get locks
                $new_dbServer.locks = $new_dbServer | Get-MonkeyAzLockInfo
                #Get diagnostic settings
                If($InputObject.supportsDiagnosticSettings -eq $True){
                    $p = @{
		                Id = $new_dbServer.Id;
                        ApiVersion = $diag_settings_api_Version;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $new_dbServer.diagnosticSettings.enabled = $true;
                        $new_dbServer.diagnosticSettings.name = $diag.name;
                        $new_dbServer.diagnosticSettings.id = $diag.id;
                        $new_dbServer.diagnosticSettings.properties = $diag.properties;
                        $new_dbServer.diagnosticSettings.rawData = $diag;
                    }
                }
                return $new_dbServer
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}
