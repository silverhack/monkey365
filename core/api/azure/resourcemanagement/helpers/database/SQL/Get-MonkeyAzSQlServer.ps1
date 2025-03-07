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

Function Get-MonkeyAzSQlServer {
    <#
        .SYNOPSIS
		Get sql server from Azure

        .DESCRIPTION
		Get sql server from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQlServer
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2021-05-01-preview"
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
		    $dbServer = Get-MonkeyAzObjectById @p
            if($dbServer){
                $new_dbServer = New-MonkeyDatabaseServerObject -Server $dbServer
                if($new_dbServer){
                    #Get Databases
                    $databases = $new_dbServer | Get-MonkeyAzSQlDatabase
                    if($databases){
                        $new_dbServer.databases = $databases;
                    }
                    #Get Vulnerability config
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$va = Get-MonkeyAzSQlVaConfig @p
                    if($va){
                        $new_dbServer.vaConfig = $va;
                    }
                    #######Get Server Threat Detection Policy########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$tdp = Get-MonkeyAzServerThreatDetectionPolicy @p
                    if($tdp){
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
                    if($tde){
                        $new_dbServer.tdeSettings.protectorMode = $tde.kind;
                        $new_dbServer.tdeSettings.properties.keyName = $tde.properties.serverKeyName;
                        $new_dbServer.tdeSettings.properties.keyType = $tde.properties.serverKeyType;
                        $new_dbServer.tdeSettings.properties.autoRotationEnabled = $tde.properties.autoRotationEnabled;
                        if($null -ne $tde.properties.PsObject.Properties.Item('uri')){
                            $new_dbServer.tdeSettings.protectorUri = $tde.Properties.uri;
                        }
                        $new_dbServer.tdeSettings.rawData = $tde;
                    }
                    #######Get Server Auditing Policy########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$audit = Get-MonkeyAzSQlServerAuditConfig @p
                    if($audit){
                        $new_dbServer.auditing.enabled = $audit.properties.state;
                        $new_dbServer.auditing.auditActionsAndGroups = $audit.properties.auditActionsAndGroups;
                        $new_dbServer.auditing.retentionDays = -1;
                        $new_dbServer.auditing.isAzureMonitorTargetEnabled = $audit.properties.isAzureMonitorTargetEnabled;
                        $new_dbServer.auditing.isStorageSecondaryKeyInUse = $audit.properties.isStorageSecondaryKeyInUse;
                        if($null -ne $audit.properties.PsObject.Properties.Item('storageAccountAccessKey')){
                            $new_dbServer.auditing.storageAccountAccessKey = $audit.properties.storageAccountAccessKey;
                        }
                        $new_dbServer.auditing.rawData = $audit;
                    }
                    #######Get Azure Active Directory admin########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$aadAdmin = Get-MonkeyAzSQlServerAdmin @p
                    if($aadAdmin){
                        $new_dbServer.sqlAd.enabled = $True;
                        $new_dbServer.sqlAd.type = $aadAdmin.properties.administratorType;
                        $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.login;
                        $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.sid;
                        $new_dbServer.sqlAd.login.tenantId = $aadAdmin.properties.tenantId;
                        $new_dbServer.sqlAd.login.azureADOnlyAuthentication = $aadAdmin.properties.azureADOnlyAuthentication;
                        $new_dbServer.sqlAd.rawData = $aadAdmin;
                    }
                    #######Get Firewall rules########
                    $p = @{
						Server = $new_dbServer;
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$fwRules = Get-MonkeyAzSqlFirewall @p
                    if($fwRules){
                        $new_dbServer.fwRules = $fwRules;
                    }
                    #######Get Connection policy########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$connectionPolicy = Get-MonkeyAzSQLServerConnectionPolicy @p
                    if($connectionPolicy){
                        $new_dbServer.networking.connectionPolicy = $connectionPolicy;
                    }
                    #######Get Private Endpoint connections########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$PEConnection = Get-MonkeyAzSQLServerPrivateEndpointConnection @p
                    if($PEConnection){
                        $new_dbServer.networking.privateEndpointConnections = $PEConnection;
                    }
                    #######Get virtual network rules########
                    $p = @{
						Server = $new_dbServer;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$virtualNetwork = Get-MonkeyAzServerVirtualNetworkRule @p
                    if($virtualNetwork){
                        $new_dbServer.networking.virtualNetworkRules = $virtualNetwork;
                    }
                    #Get locks
                    $new_dbServer.locks = $new_dbServer | Get-MonkeyAzLockInfo
                    #Get diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
		                    Id = $new_dbServer.Id;
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
                    #Get Failover group
                    $new_dbServer.failoverGroups = $new_dbServer | Get-MonkeyAzSQLFailoverGroup
                }
                return $new_dbServer
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}

