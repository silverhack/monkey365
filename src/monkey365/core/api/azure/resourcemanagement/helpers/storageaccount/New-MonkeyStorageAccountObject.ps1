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

Function New-MonkeyStorageAccountObject {
<#
        .SYNOPSIS
		Create a new storage account object

        .DESCRIPTION
		Create a new storage account object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyStorageAccountObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Storate account object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $strObject = [ordered]@{
                id = $InputObject | Select-Object -ExpandProperty Id -ErrorAction Ignore;
		        name = $InputObject | Select-Object -ExpandProperty Name -ErrorAction Ignore;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore;
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore;
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                kind = $InputObject | Select-Object -ExpandProperty kind -ErrorAction Ignore;
                skuName = $InputObject.sku.Name;
                skuTier = $InputObject.sku.tier;
		        CreationTime = $InputObject.properties.CreationTime;
                primaryLocation = $InputObject.properties.primaryLocation;
                statusofPrimary = $InputObject.properties.statusOfPrimary;
                allowSharedKeyAccess = $InputObject.properties | Select-Object -ExpandProperty allowSharedKeyAccess -ErrorAction Ignore;
                sftp = [PSCustomObject]@{
                    enabled = If($null -ne $InputObject.properties.Psobject.Properties.Item('isSftpEnabled')){$InputObject.properties.isSftpEnabled}else{$false};
                    localUsers = $null;
                };
                dataStorage = [PSCustomObject]@{
                    containers = $null;
                    fileShares = $null;
                    queues = $null;
                    tables = $null;
                };
                networking = [PSCustomObject]@{
                    minimumTlsVersion = $InputObject.properties | Select-Object -ExpandProperty minimumTlsVersion -ErrorAction Ignore
                    supportsHttpsTrafficOnly = $InputObject.properties.supportsHttpsTrafficOnly;
                    allowCrossTenantReplication = if($null -ne $InputObject.properties.Psobject.Properties.Item('allowCrossTenantReplication')){$InputObject.properties.allowCrossTenantReplication}else{$true};
                    allowAzureServices = $InputObject.properties.networkAcls.bypass -match 'AzureServices';
                    allowAccessFromAllNetworks = if (-not $InputObject.properties.networkAcls.virtualNetworkRules -and -not $InputObject.properties.networkAcls.ipRules -and $InputObject.properties.networkAcls.defaultAction -eq 'Allow'){$true}else{$false};
                    publicNetworkAccess = $InputObject.properties | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore
                    networkAclBypass = $InputObject.properties.networkAcls | Select-Object -ExpandProperty bypass -ErrorAction Ignore
                    ipRules = $InputObject.properties.networkAcls| Select-Object -ExpandProperty ipRules -ErrorAction Ignore
                    virtualNetworkRules = $InputObject.properties.networkAcls | Select-Object -ExpandProperty virtualNetworkRules -ErrorAction Ignore
                    resourceAccessRules = $InputObject.properties.networkAcls | Select-Object -ExpandProperty resourceAccessRules -ErrorAction Ignore
                    ipv6Rules = $InputObject.properties.networkAcls | Select-Object -ExpandProperty ipv6Rules -ErrorAction Ignore
                    privateEndpointConnections = $InputObject.properties | Select-Object -ExpandProperty privateEndpointConnections -ErrorAction Ignore ;
                    networkSecurityPerimeterConfigurations = $null;
                    privateLinkResources = $null;
                };
                primaryEndpoints = [PSCustomObject]@{
                    blobEndpoint = If($InputObject.properties.primaryEndpoints.Psobject.Properties.Item('blob')){$InputObject.properties.primaryEndpoints.blob}Else{$null};
                    queueEndpoint = If($InputObject.properties.primaryEndpoints.Psobject.Properties.Item('queue')){$InputObject.properties.primaryEndpoints.queue}Else{$null};
                    tableEndpoint = If($InputObject.properties.primaryEndpoints.Psobject.Properties.Item('Table')){$InputObject.properties.primaryEndpoints.Table}Else{$null};
                    fileEndpoint = If($InputObject.properties.primaryEndpoints.Psobject.Properties.Item('File')){$InputObject.properties.primaryEndpoints.File}Else{$null};
                    webEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('Web')){$InputObject.properties.primaryEndpoints.Web}Else{$null};
                    dfsEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('Web')){$InputObject.properties.primaryEndpoints.dfs}Else{$null};
                };
                keys = [PSCustomObject]@{
                    keyRotation = [PSCustomObject]@{
                        key1 = [PSCustomObject]@{
                            lastRotatedInDays = $null;
                            keyCreationTime = $null;
                        };
                        key2 = [PSCustomObject]@{
                            lastRotatedInDays = $null;
                            keyCreationTime = $null;
                        };
                    };
                    keyPolicy = [PSCustomObject]@{
                        keyExpirationPeriodInDays = $null;
                        enableAutoRotation = $null;
                    }
                };
                encryption = [PSCustomObject]@{
                    requireInfrastructureEncryption = If($null -eq $InputObject.properties.encryption.PSObject.Properties.Item('requireInfrastructureEncryption')){$false}Else{$InputObject.properties.encryption.requireInfrastructureEncryption};
                    services = [PSCustomObject]@{
                        blob = [PSCustomObject]@{
                            keyType = $InputObject.properties.encryption.services.blob.keyType;
                            enabled = $InputObject.properties.encryption.services.blob.enabled;
                            lastEnabledTime = $InputObject.properties.encryption.services.blob.lastEnabledTime;
                        };
                        file = [PSCustomObject]@{
                            keyType = $InputObject.properties.encryption.services.file.keyType;
                            enabled = $InputObject.properties.encryption.services.file.enabled;
                            lastEnabledTime = $InputObject.properties.encryption.services.file.lastEnabledTime;
                        };
                    };
                    keyVault = [PSCustomObject]@{
                        keyvaulturi = $null;
                        keyname = $null;
                        keyversion = $null;
                        enabled = $false;
                    };
                };
                dataProtection = [PSCustomObject]@{
                    isVersioningEnabled = $null;
                    cors = $null;
                    staticWebsite = [PSCustomObject]@{
                        enabled = $null;
                    };
                    restorePolicy = [PSCustomObject]@{
                        days = $null;
                        enabled = $null;
                        lastEnabledTime = $null;
                        minRestoreTime = $null;
                    };
                    deleteRetentionPolicy= [PSCustomObject]@{
                        allowPermanentDelete = $null;
                        days = $null;
                        enabled = $null;
                    };
                    containerDeleteRetentionPolicy = [PSCustomObject]@{
                        allowPermanentDelete = $null;
                        days = $null;
                        enabled = $null;
                    };
                    changeFeed = [PSCustomObject]@{
                        retentionInDays = $null;
                        enabled = $null;
                    };
                    rawObject = $null;
                };
                fileProtection = $null;
                threatProtection = [PSCustomObject]@{
                    advancedProtection = [PSCustomObject]@{
                        enabled = $null;
                        rawObject = $null;
                    };
                    defenderForStorage = $null;
                };
                containers = $null;
                diagnosticSettings = [PSCustomObject]@{
                    file = $null;
                    queue = $null;
                    blob = $null;
                    table = $null;
                };
                locks = $null;
                rawObject = $InputObject;
            }
            #Create PsObject
            $str_obj = New-Object -TypeName PsObject -Property $strObject
            #return object
            return $str_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.StorageObjectCreationFailed);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('StorageAccountObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "StorageAccountObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
