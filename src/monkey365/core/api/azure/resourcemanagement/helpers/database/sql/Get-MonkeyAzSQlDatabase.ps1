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

Function Get-MonkeyAzSQlDatabase {
    <#
        .SYNOPSIS
		Get sql databases from Azure

        .DESCRIPTION
		Get sql databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQlDatabase
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-01-01"
    )
    Process{
        Try{
            $all_databases = [System.Collections.Generic.List[System.Object]]::new()
            $p = @{
			    Id = ($InputObject.Id).Substring(1);
                Resource = "databases";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $databases = Get-MonkeyAzObjectById @p
            ForEach($database in @($databases)){
                $new_db = $database | New-MonkeyDatabaseObject
                If ($new_db.Name -ne "master") {
                    #######Get database backup short term policy Status########
                    $p = @{
						Database = $new_db;
                        ShortTermRetentionPolicy = $True;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$new_db.backup.shortTermRetentionPolicy = Get-MonkeyAzDatabaseBackupConfiguration @p
                    #######Get database backup long term backup Status########
                    $p = @{
						Database = $new_db;
                        LongTermRetentionBackup = $True;
                        onlyLatestPerDatabase = $True;
                        DatabaseState = "Live";
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$new_db.backup.longTermRetentionBackups = Get-MonkeyAzDatabaseBackupConfiguration @p
                    #######Get database Transparent Data Encryption Status########
                    $msg = @{
						MessageData = ($message.DatabaseServerTDEMessage -f $new_db.Name);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $O365Object.InformationAction;
						Tags = @('AzureSQLServerInfo');
					}
					Write-Information @msg
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$tde = Get-MonkeyAzDatabaseTdeConfig @p
                    If($tde){
                        $new_db.tdeSettings.status = $tde.properties.state
                        $new_db.tdeSettings.rawData = $tde;
                    }
                    #######Get Database Auditing Policy########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$audit = Get-MonkeyAzDatabaseAuditConfig @p
                    If($audit){
                        $new_db.auditing.status = $audit.properties.state;
                        $new_db.auditing.retentionDays = $audit.properties.retentionDays;
                        $new_db.auditing.isAzureMonitorTargetEnabled = $audit.properties.isAzureMonitorTargetEnabled;
                        if($audit.properties.Psobject.Properties.Item('auditActionsAndGroups')){
                            $new_db.auditing.auditActionsAndGroups = (@($audit.Properties.auditActionsAndGroups) -join ',');
                        }
                        $new_db.auditing.rawData = $audit;
                    }
                    #######Get Database Threat Detection Policy########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$tdp = Get-MonkeyAzDatabaseThreatDetectionPolicy @p
                    If($tdp){
                        $new_db.tdpSettings.status = $tdp.properties.state;
                        $new_db.tdpSettings.disabledAlerts = $tdp.properties.disabledAlerts;
                        $new_db.tdpSettings.emailAddresses = $tdp.properties.emailAddresses;
                        $new_db.tdpSettings.sentToAdmins = $tdp.properties.emailAccountAdmins;
                        $new_db.tdpSettings.retentionDays = $tdp.properties.retentionDays;
                        $new_db.tdpSettings.rawData = $tdp;
                    }
                    #######Get Database ledger configuration########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$ledger = Get-MonkeyAzDatabaseLedgerConfig @p
                    If($ledger){
                        $new_db.ledger.status = $ledger.properties.state;
                        $new_db.ledger.rawData = $ledger;
                    }
                    #######Get Database masking########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$maskingPolicy = Get-MonkeyAzDBDataMaskingPolicy @p
                    If($maskingPolicy){
                        $new_db.dataMaskingPolicies.status = $maskingPolicy.properties.dataMaskingState;
                        $new_db.dataMaskingPolicies.rawData = $maskingPolicy;
                    }
                    #######Get Database masking rules########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$new_db.dataMaskingRules.rawData = Get-MonkeyAzDBDataMaskingRule @p
                    #######Get Database recommended sensitivity labels########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$new_db.dataClassification.rawData = Get-MonkeyAzDBRecommendedSensitivityLabel @p
                    #######Get Database current sensitivity labels########
                    $p = @{
						Database = $new_db;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$new_db.sensitivityLabel.rawData = Get-MonkeyAzDBSensitivityLabel @p
                }
                Else{
                    $new_db.tdeSettings.status = $false;
                }
                #add to array
                [void]$all_databases.Add($new_db)
            }
            #return object
            Write-Output $all_databases -NoEnumerate
        }
        Catch{
            Write-Verbose $_
        }
    }
}
