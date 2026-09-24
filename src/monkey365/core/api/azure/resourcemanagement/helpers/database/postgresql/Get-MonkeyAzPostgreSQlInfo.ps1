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

Function Get-MonkeyAzPostgreSQlInfo {
    <#
        .SYNOPSIS
		Get PostgreSql server from Azure

        .DESCRIPTION
		Get PostgreSql server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPostgreSQlInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-08-01"
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
                #Get Encryption if any
                $new_dbServer.encryption = $dbServer.properties | Select-Object -ExpandProperty dataEncryption -ErrorAction Ignore;
                #Get Public network access
                $new_dbServer.networking.publicNetworkAccess = $dbServer.properties.network | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore;
                #Get subnet if any
                $new_dbServer.networking.subnet = $dbServer.properties.network | Select-Object -ExpandProperty delegatedSubnetResourceId -ErrorAction Ignore;
                #Get Virtual network Id if any
                If($new_dbServer.networking.subnet){
                    $new_dbServer.networking.virtualNetworkId = $new_dbServer.networking.subnet.Remove($new_dbServer.networking.subnet.LastIndexOf('/subnets/'))
                }
                #Get Private DNS if exists
                $new_dbServer.networking.privateDNS = $dbServer.properties.network | Select-Object -ExpandProperty privateDnsZoneArmResourceId -ErrorAction Ignore;
                #Check if infrastructure encryption is enabled
                $encryption = $dbServer.properties | Select-Object -ExpandProperty encryption -ErrorAction Ignore
                If($null -ne $encryption){
                    $new_dbServer.requireInfrastructureEncryption = $encryption | Select-Object -ExpandProperty infrastructureEncryption -ErrorAction Ignore
                }
                Else{
                    $new_dbServer.requireInfrastructureEncryption = $false
                }
                #Get Databases
                $new_dbServer.databases = $new_dbServer | Get-MonkeyAzPostgreSQLDatabase -APIVersion $APIVersion
                #Get Configuration
                $new_dbServer.configuration = $new_dbServer | Get-MonkeyAzOSSQlConfig -APIVersion $APIVersion
                If($new_dbServer.configuration){
                    #Get Tls version
                    $new_dbServer.networking.minimumTlsVersion = $new_dbServer.configuration.Where({$_.parameterName -eq 'ssl_min_protocol_version'}) | Select-Object -ExpandProperty parameterValue
                }
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
                    If($diag){
                        #Add to object
                        $new_dbServer.diagnosticSettings.enabled = $true;
                        $new_dbServer.diagnosticSettings.name = $diag.name;
                        $new_dbServer.diagnosticSettings.id = $diag.id;
                        $new_dbServer.diagnosticSettings.properties = $diag.properties;
                        $new_dbServer.diagnosticSettings.rawData = $diag;
                    }
                }
                #######Get Server Threat Detection Policy########
                $p = @{
					Server = $new_dbServer;
                    ApiVersion = $APIVersion;
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
                #######Get Entra ID admin ########
                $p = @{
					InputObject = $new_dbServer;
                    APIVersion = $APIVersion;
                    OSSSql = $True;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$aadAdmin = Get-MonkeyAzSQlServerAdmin @p
                If($aadAdmin){
                    $new_dbServer.sqlAd.enabled = $True;
                    If($null -ne $aadAdmin.properties.PsObject.properties.Item('administratorType')){
                        $new_dbServer.sqlAd.type = $aadAdmin.properties.administratorType;
                    }
                    ElseIf($null -ne $aadAdmin.properties.PsObject.properties.Item('principalType')){
                        $new_dbServer.sqlAd.type = $aadAdmin.properties.principalType;
                    }
                    If($null -ne $aadAdmin.properties.PsObject.properties.Item('login')){
                        $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.login;
                    }
                    ElseIf($null -ne $aadAdmin.properties.PsObject.properties.Item('principalName')){
                        $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.principalName;
                    }
                    If($null -ne $aadAdmin.properties.PsObject.properties.Item('sid')){
                        $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.sid;
                    }
                    ElseIf($null -ne $aadAdmin.properties.PsObject.properties.Item('objectId')){
                        $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.objectId;
                    }
                    $new_dbServer.sqlAd.login.tenantId = $aadAdmin.properties.tenantId;
                    If($null -ne $aadAdmin.properties.PsObject.Properties.Item('azureADOnlyAuthentication')){
                        $new_dbServer.sqlAd.login.azureADOnlyAuthentication = $aadAdmin.properties.azureADOnlyAuthentication;
                    }
                    $new_dbServer.sqlAd.rawData = $aadAdmin;
                }
                #Check if Only EID is supported
                $eidAuth = $new_dbServer.properties.authConfig | Select-Object -ExpandProperty activeDirectoryAuth -ErrorAction Ignore
                $passwordAuth = $new_dbServer.properties.authConfig | Select-Object -ExpandProperty passwordAuth -ErrorAction Ignore
                If($passwordAuth.ToLower() -eq 'disabled' -and $eidAuth.ToLower() -eq "enabled"){
                    $new_dbServer.sqlAd.entraIdOnlyAuthentication.enabled = $True
                }
                Else{
                    $new_dbServer.sqlAd.entraIdOnlyAuthentication.enabled = $false
                }
                #######Get Private Endpoint connections########
                $p = @{
					InputObject = $new_dbServer;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.networking.privateEndpointConnections = Get-MonkeyAzGenericPrivateEndpoint @p
                #######Get backup if any ########
                $p = @{
					InputObject = $new_dbServer;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.backups = Get-MonkeyAzOSSqllBackup @p
                #######Get Firewall rules########
                $p = @{
					Server = $new_dbServer;
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
				}
				$new_dbServer.networking.firewall = Get-MonkeyAzSqlFirewall @p
                # return object
                return $new_dbServer
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
