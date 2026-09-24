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
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="server object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $DatabaseObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore
                sku = $InputObject | Select-Object -ExpandProperty sku -ErrorAction Ignore
                kind = $InputObject | Select-Object -ExpandProperty kind -ErrorAction Ignore
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore
                identity = $InputObject | Select-Object -ExpandProperty identity -ErrorAction Ignore
                systemData = $InputObject | Select-Object -ExpandProperty systemData -ErrorAction Ignore
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore
                resourceGroupName = $InputObject.Id.Split("/")[4];
		        fqdn = $InputObject.properties | Select-Object -ExpandProperty fullyQualifiedDomainName -ErrorAction Ignore
                administratorLogin = $InputObject.properties | Select-Object -ExpandProperty administratorLogin -ErrorAction Ignore
                encryption = $null;
                requireInfrastructureEncryption = $false;
                networking = [PSCustomObject]@{
                    minimumTlsVersion = if($null -ne $InputObject.properties.PsObject.Properties.Item('minimalTlsVersion')){$InputObject.properties.minimalTlsVersion}else{$null};
                    settings = [PSCustomObject]@{
                        hostName = $InputObject.properties | Select-Object -ExpandProperty fullyQualifiedDomainName -ErrorAction Ignore
                        port = $InputObject.properties | Select-Object -ExpandProperty databasePort -ErrorAction Ignore
                        staticIP = $InputObject.properties | Select-Object -ExpandProperty staticIP -ErrorAction Ignore
                    };
                    publicNetworkAccess = $null;
                    subnet = $null;
                    virtualNetworkId = $null;
                    firewall = $null;
                    privateEndpointConnections = $InputObject.properties | Select-Object -ExpandProperty privateEndpointConnections -ErrorAction Ignore
                    privateLink = $null;
                    virtualNetworkRules = $null;
                    privateDNS = $null;
                    connectionPolicy = $null;
                };
                sqlAd = [PSCustomObject]@{
                    enabled = $false;
                    type = $null;
                    entraIdOnlyAuthentication = [PSCustomObject]@{
                        enabled = $null;
                        rawData = $null;
                    };
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
                configuration = $null;
                failoverGroups = $null;
                databases = $null;
                backups = $null;
                locks = $null;
                rawObject = $InputObject;
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
