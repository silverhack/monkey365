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

Function New-MonkeyDatabaseServerObject {
<#
        .SYNOPSIS
		Create a new database server object

        .DESCRIPTION
		Create a new database server object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyDatabaseServerObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, HelpMessage="server object")]
        [Object]$Server
    )
    Process{
        try{
            #Create ordered dictionary
            $DatabaseObject = [ordered]@{
                id = $Server.Id;
		        name = $Server.Name;
                type = $Server.type;
                location = $Server.location;
                identity = if($null -ne $Server.PsObject.Properties.Item('identity')){$Server.identity}else{$null};
		        tags = $Server.tags;
                properties = $Server.properties;
                resourceGroupName = $Server.Id.Split("/")[4];
                kind = if($null -ne $Server.PsObject.Properties.Item('kind')){$Server.kind}else{$null};
		        fqdn = $Server.properties.fullyQualifiedDomainName;
                administratorLogin = $Server.properties.administratorLogin;
                minimalTlsVersion = if($null -ne $Server.properties.PsObject.Properties.Item('minimalTlsVersion')){$Server.properties.minimalTlsVersion}else{$null};
                sqlAd = [PSCustomObject]@{
                    enabled = $false;
                    type = $null;
                    login = [PSCustomObject]@{
                        adlogin = $null;
                        sid = $null;
                        tenantId = $null;
                        azureADOnlyAuthentication = $null;
                    };
                    rawData = $null;
                };
                tdeSettings = [PSCustomObject]@{
                    protectorUri = $null;
                    protectorMode = $null;
                    properties = [PSCustomObject]@{
                        keyName = $null;
                        keyType = $null;
                        autoRotationEnabled = $null;
                    };
                    rawData = $null;
                };
                tdpSettings = [PSCustomObject]@{
                    enabled = $false;
                    disabledAlerts = $null;
                    emailAddresses = $null;
                    sentToAdmins = $null;
                    retentionDays = $null;
                    rawData = $null;
                };
                auditing = [PSCustomObject]@{
                    enabled = $false;
                    auditActionsAndGroups = $null;
                    retentionDays = $null;
                    isAzureMonitorTargetEnabled = $null;
                    storageAccountAccessKey = $null;
                    isStorageSecondaryKeyInUse= $null;
                    rawData = $null;
                };
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                vaConfig = $null;
                fwRules = $null;
                configuration = $null;
                failoverGroups = $null;
                databases = $null;
                locks = $null;
                rawObject = $Server;
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
