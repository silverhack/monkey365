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
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Database object")]
        [Object]$Inputobject
    )
    Process{
        try{
            #Create ordered dictionary
            $DatabaseObject = [ordered]@{
                id = $Inputobject.Id;
		        name = $Inputobject.Name;
                type = if($null -ne $Inputobject.PsObject.properties.Item('type')){$Inputobject.type}else{$null};
                location = if($null -ne $Inputobject.PsObject.properties.Item('location')){$Inputobject.location}else{$null};
                kind = if($null -ne $Inputobject.PsObject.properties.Item('kind')){$Inputobject.kind}else{$null};
                sku = if($null -ne $Inputobject.PsObject.properties.Item('sku')){$Inputobject.sku}else{$null};
                managedBy = if($null -ne $Inputobject.Psobject.Properties.Item('managedBy')){$Inputobject.managedBy}else{$null};
                properties = $Inputobject.properties;
                collation = $Inputobject.properties.collation;
		        maxSizeBytes = if($null -ne $Inputobject.properties.PsObject.properties.Item('maxSizeBytes')){$Inputobject.properties.maxSizeBytes}else{$null};
                creationDate = if($null -ne $Inputobject.properties.PsObject.properties.Item('creationDate')){$Inputobject.properties.creationDate}else{$null};
                defaultSecondaryLocation = if($null -ne $Inputobject.properties.PsObject.properties.Item('defaultSecondaryLocation')){$Inputobject.properties.defaultSecondaryLocation}else{$null};
                readScale = if($null -ne $Inputobject.properties.PsObject.properties.Item('readScale')){$Inputobject.properties.readScale}else{$null};
                locks = $null;
                backup = [PSCustomObject]@{
                    shortTermRetentionPolicy = $null;
                    longTermRetentionBackups = $null;
                };
                tdeSettings = [PSCustomObject]@{
                    status = $false;
                    rawData = $null;
                };
                tdpSettings = [PSCustomObject]@{
                    status = $null;
                    disabledAlerts = $null;
                    emailAddresses = $null;
                    sentToAdmins = $null;
                    retentionDays = $null;
                    rawData = $null;
                };
                auditing = [PSCustomObject]@{
                    status = $null;
                    auditActionsAndGroups = $null;
                    isAzureMonitorTargetEnabled = $null;
                    retentionDays = $null;
                    rawData = $null;
                };
                ledger = [PSCustomObject]@{
                    status = $null;
                    rawData = $null;
                };
                dataMaskingPolicies = [PSCustomObject]@{
                    status = $null;
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
                rawObject = $Inputobject;
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
