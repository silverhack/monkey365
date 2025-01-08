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

Function New-MonkeyDatabaseObject {
<#
        .SYNOPSIS
		Create a new database object

        .DESCRIPTION
		Create a new database object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyDatabaseObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, HelpMessage="Database object")]
        [Object]$Database
    )
    Process{
        try{
            #Create ordered dictionary
            $DatabaseObject = [ordered]@{
                id = $Database.Id;
		        name = $Database.Name;
                type = if($null -ne $Database.PsObject.properties.Item('type')){$Database.type}else{$null};
                location = if($null -ne $Database.PsObject.properties.Item('location')){$Database.location}else{$null};
                kind = if($null -ne $Database.PsObject.properties.Item('kind')){$Database.kind}else{$null};
                sku = if($null -ne $Database.PsObject.properties.Item('sku')){$Database.sku}else{$null};
                managedBy = if($null -ne $Database.Psobject.Properties.Item('managedBy')){$Database.managedBy}else{$null};
                properties = $Database.properties;
                collation = $Database.properties.collation;
		        maxSizeBytes = if($null -ne $Database.properties.PsObject.properties.Item('maxSizeBytes')){$Database.properties.maxSizeBytes}else{$null};
                creationDate = if($null -ne $Database.properties.PsObject.properties.Item('creationDate')){$Database.properties.creationDate}else{$null};
                defaultSecondaryLocation = if($null -ne $Database.properties.PsObject.properties.Item('defaultSecondaryLocation')){$Database.properties.defaultSecondaryLocation}else{$null};
                readScale = if($null -ne $Database.properties.PsObject.properties.Item('readScale')){$Database.properties.readScale}else{$null};
                encryptionStatus = $null;
                locks = $null;
                tdeSettings = [PSCustomObject]@{
                    enabled = $null;
                    rawData = $null;
                };
                tdpSettings = [PSCustomObject]@{
                    enabled = $null;
                    disabledAlerts = $null;
                    emailAddresses = $null;
                    sentToAdmins = $null;
                    retentionDays = $null;
                    rawData = $null;
                };
                auditing = [PSCustomObject]@{
                    enabled = $null;
                    auditActionsAndGroups = $null;
                    isAzureMonitorTargetEnabled = $null;
                    retentionDays = $null;
                    rawData = $null;
                };
                ledger = [PSCustomObject]@{
                    enabled = $null;
                    rawData = $null;
                };
                dataMaskingPolicies = [PSCustomObject]@{
                    enabled = $null;
                    rawData = $null;
                };
                dataMaskingRules = [PSCustomObject]@{
                    rawData = $null;
                };
                dataClassification = [PSCustomObject]@{
                    rawData = $null;
                };
                sensitivityLabel = [PSCustomObject]@{
                    rawData = $null;
                };
                rawObject = $Database;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $DatabaseObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.DatabaseObjectCreationFailed);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('DatabaseServerObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "DatabaseServerObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
