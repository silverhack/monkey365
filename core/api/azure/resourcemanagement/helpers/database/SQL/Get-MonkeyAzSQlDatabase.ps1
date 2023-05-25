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
        [Object]$Server,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2021-05-01-preview"
    )
    Process{
        try{
            $all_databases = New-Object System.Collections.Generic.List[System.Object]
            $p = @{
			    Id = ($Server.Id).Substring(1);
                Resource = "databases";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $databases = Get-MonkeyAzObjectById @p
            if($databases){
                foreach($database in $databases){
                    $new_db = New-MonkeyDatabaseObject -Database $database
                    if($new_db){
                        if ($new_db.Name -ne "master") {
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
                            if($tde){
                                $new_db.tdeSettings.enabled = $tde.properties.state
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
                            if($audit){
                                $new_db.auditing.enabled = $audit.properties.state;
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
                            if($tdp){
                                $new_db.tdpSettings.enabled = $tdp.properties.state;
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
                            if($ledger){
                                $new_db.ledger.enabled = $ledger.properties.state;
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
                            if($maskingPolicy){
                                $new_db.dataMaskingPolicies.enabled = $maskingPolicy.properties.dataMaskingState;
                                $new_db.dataMaskingPolicies.rawData = $maskingPolicy;
                            }
                            #######Get Database masking rules########
                            $p = @{
							    Database = $new_db;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
						    }
						    $maskingRule = Get-MonkeyAzDBDataMaskingRule @p
                            if($maskingRule){
                                $new_db.dataMaskingRules.rawData = $maskingRule;
                            }
                            #######Get Database recommended sensitivity labels########
                            $p = @{
							    Database = $new_db;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
						    }
						    $recommendedSL = Get-MonkeyAzDBRecommendedSensitivityLabel @p
                            if($recommendedSL){
                                $new_db.dataClassification.rawData = $recommendedSL;
                            }
                            #######Get Database current sensitivity labels########
                            $p = @{
							    Database = $new_db;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
						    }
						    $CurrentSL = Get-MonkeyAzDBSensitivityLabel @p
                            if($CurrentSL){
                                $new_db.sensitivityLabel.rawData = $CurrentSL;
                            }
                        }
                        else{
                            $new_db.tdeSettings.enabled = $false;
                        }
                        #add to array
                        [void]$all_databases.Add($new_db)
                    }
                }
            }
            #return object
            Write-Output $all_databases -NoEnumerate

        }
        catch{
            Write-Verbose $_
        }
    }
}