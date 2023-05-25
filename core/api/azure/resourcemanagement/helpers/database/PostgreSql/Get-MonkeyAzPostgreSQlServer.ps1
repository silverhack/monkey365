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

Function Get-MonkeyAzPostgreSQlServer {
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
            File Name	: Get-MonkeyAzPostgreSQlServer
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$Server,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2017-12-01"
    )
    Process{
        try{
            $p = @{
			    Id = $Server.Id;
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
                    $databases = $new_dbServer | Get-MonkeyAzPostgreSQLDatabase -APIVersion $APIVersion
                    if($databases){
                        $new_dbServer.databases = $databases;
                    }
                    #Get Configuration
                    $configuration = $new_dbServer | Get-MonkeyAzOSSQlConfig -APIVersion $APIVersion
                    if($configuration){
                        $new_dbServer.configuration = $configuration;
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
                    if($tdp){
                        $new_dbServer.tdpSettings.enabled = $tdp.properties.state;
                        $new_dbServer.tdpSettings.disabledAlerts = $tdp.properties.disabledAlerts;
                        $new_dbServer.tdpSettings.emailAddresses = $tdp.properties.emailAddresses;
                        $new_dbServer.tdpSettings.sentToAdmins = $tdp.properties.emailAccountAdmins;
                        $new_dbServer.tdpSettings.retentionDays = $tdp.properties.retentionDays;
                        $new_dbServer.tdpSettings.rawData = $tdp;
                    }
                    #######Get Azure Active Directory admin########
                    $p = @{
						Server = $new_dbServer;
                        APIVersion = $APIVersion;
                        PostgreSQL = $True;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$aadAdmin = Get-MonkeyAzSQlServerAdmin @p
                    if($aadAdmin){
                        $new_dbServer.sqlAd.enabled = $True;
                        if($null -ne $aadAdmin.properties.PsObject.properties.Item('administratorType')){
                            $new_dbServer.sqlAd.type = $aadAdmin.properties.administratorType;
                        }
                        elseif($null -ne $aadAdmin.properties.PsObject.properties.Item('principalType')){
                            $new_dbServer.sqlAd.type = $aadAdmin.properties.principalType;
                        }
                        if($null -ne $aadAdmin.properties.PsObject.properties.Item('login')){
                            $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.login;
                        }
                        elseif($null -ne $aadAdmin.properties.PsObject.properties.Item('principalName')){
                            $new_dbServer.sqlAd.login.adlogin = $aadAdmin.properties.principalName;
                        }
                        if($null -ne $aadAdmin.properties.PsObject.properties.Item('sid')){
                            $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.sid;
                        }
                        elseif($null -ne $aadAdmin.properties.PsObject.properties.Item('objectId')){
                            $new_dbServer.sqlAd.login.sid = $aadAdmin.properties.objectId;
                        }
                        $new_dbServer.sqlAd.login.tenantId = $aadAdmin.properties.tenantId;
                        if($null -ne $aadAdmin.properties.PsObject.Properties.Item('azureADOnlyAuthentication')){
                            $new_dbServer.sqlAd.login.azureADOnlyAuthentication = $aadAdmin.properties.azureADOnlyAuthentication;
                        }
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
                }
                return $new_dbServer
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}