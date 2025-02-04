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
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                properties = $InputObject.Properties;
                allowCrossTenantReplication = if($null -ne $InputObject.properties.Psobject.Properties.Item('allowCrossTenantReplication')){$InputObject.properties.allowCrossTenantReplication}else{$true};
                resourceGroupName = $InputObject.Id.Split("/")[4];
                kind = $InputObject.kind;
                skuName = $InputObject.SKU.Name;
                skuTier = $InputObject.SKU.tier;
		        CreationTime = $InputObject.Properties.CreationTime;
                primaryLocation = $InputObject.Properties.primaryLocation;
                statusofPrimary = $InputObject.Properties.statusOfPrimary;
                supportsHttpsTrafficOnly = $InputObject.Properties.supportsHttpsTrafficOnly;
                requireInfrastructureEncryption = $false;
                blobEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('blob')){$InputObject.Properties.primaryEndpoints.blob}Else{$null};
                queueEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('queue')){$InputObject.Properties.primaryEndpoints.queue}Else{$null};
                tableEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('Table')){$InputObject.Properties.primaryEndpoints.Table}Else{$null};
                fileEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('File')){$InputObject.Properties.primaryEndpoints.File}Else{$null};
                webEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('Web')){$InputObject.Properties.primaryEndpoints.Web}Else{$null};
                dfsEndpoint = If($InputObject.Properties.primaryEndpoints.Psobject.Properties.Item('Web')){$InputObject.Properties.primaryEndpoints.dfs}Else{$null};
                keyRotation = [PSCustomObject]@{
                    key1 = [PSCustomObject]@{
                        isRotated = $null;
                        lastRotationDate = $null;
                    };
                    key2 = [PSCustomObject]@{
                        isRotated = $null;
                        lastRotationDate = $null;
                    };
                };
                keyvaulturi = $null;
                keyname = $null;
                keyversion = $null;
                usingOwnKey = $false;
                isBlobEncrypted = $InputObject.Properties.encryption.services.blob.Enabled;
                lastBlobEncryptionEnabledTime = $InputObject.Properties.encryption.services.blob.lastEnabledTime;
                isFileEncrypted = $InputObject.Properties.encryption.services.File.Enabled;
                lastFileEnabledTime = $InputObject.Properties.encryption.services.File.lastEnabledTime;
                isEncrypted = $null;
                lastEnabledTime = $null;
                allowAzureServices = $InputObject.Properties.networkAcls.bypass -match 'AzureServices';
                allowAccessFromAllNetworks = if (-not $InputObject.Properties.networkAcls.virtualNetworkRules -and -not $InputObject.Properties.networkAcls.ipRules -and $InputObject.Properties.networkAcls.defaultAction -eq 'Allow'){$true}else{$false};
                dataProtection = $null;
                advancedProtectionEnabled = $null;
                atpRawObject = $null;
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

