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
        [parameter(Mandatory= $True, HelpMessage="Storate account object")]
        [Object]$StrAccount
    )
    Process{
        try{
            #Create ordered dictionary
            $strObject = [ordered]@{
                id = $StrAccount.Id;
		        name = $StrAccount.Name;
                location = $StrAccount.location;
		        tags = $StrAccount.tags;
                properties = $StrAccount.Properties;
                resourceGroupName = $StrAccount.Id.Split("/")[4];
                kind = $StrAccount.kind;
                skuName = $StrAccount.SKU.Name;
                skuTier = $StrAccount.SKU.tier;
		        CreationTime = $StrAccount.Properties.CreationTime;
                primaryLocation = $StrAccount.Properties.primaryLocation;
                statusofPrimary = $StrAccount.Properties.statusOfPrimary;
                supportsHttpsTrafficOnly = $StrAccount.Properties.supportsHttpsTrafficOnly;
                requireInfrastructureEncryption = $false;
                blobEndpoint = $StrAccount.Properties.primaryEndpoints.blob;
                queueEndpoint = $StrAccount.Properties.primaryEndpoints.queue;
                tableEndpoint = $StrAccount.Properties.primaryEndpoints.Table;
                fileEndpoint = $StrAccount.Properties.primaryEndpoints.File;
                webEndpoint = $StrAccount.Properties.primaryEndpoints.Web;
                dfsEndpoint = $StrAccount.Properties.primaryEndpoints.dfs;
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
                isBlobEncrypted = $StrAccount.Properties.encryption.services.blob.Enabled;
                lastBlobEncryptionEnabledTime = $StrAccount.Properties.encryption.services.blob.lastEnabledTime;
                isFileEncrypted = $StrAccount.Properties.encryption.services.File.Enabled;
                lastFileEnabledTime = $StrAccount.Properties.encryption.services.File.lastEnabledTime;
                isEncrypted = $null;
                lastEnabledTime = $null;
                allowAzureServices = $StrAccount.Properties.networkAcls.bypass -match 'AzureServices';
                allowAccessFromAllNetworks = if (-not $StrAccount.Properties.networkAcls.virtualNetworkRules -and -not $StrAccount.Properties.networkAcls.ipRules -and $StrAccount.Properties.networkAcls.defaultAction -eq 'Allow'){$true}else{$false};
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
                rawObject = $StrAccount;
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