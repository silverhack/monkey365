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

Function New-MonkeyCosmosDBObject {
<#
        .SYNOPSIS
		Create a new CosmosDB object

        .DESCRIPTION
		Create a new CosmosDB object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyCosmosDBObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="CosmosDB object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $CDBObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
                identity = if($null -ne $InputObject.PsObject.Properties.Item('identity')){$InputObject.identity}else{$null};
		        tags = $InputObject.tags;
                properties = $InputObject.properties;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                kind = If($null -ne $InputObject.PsObject.Properties.Item('kind')){$InputObject.kind}else{$null};
		        systemData = $InputObject | Select-Object -ExpandProperty systemData -ErrorAction Ignore
                minimalTlsVersion = $InputObject.properties| Select-Object -ExpandProperty minimalTlsVersion -ErrorAction Ignore
                dataEncryption = If($null -ne $InputObject.properties.PsObject.Properties.Item('keyVaultKeyUri') -and $InputObject.properties.keyVaultKeyUri){"cmk"}else{"smk"};
                sqlRoleAssignments = $null;
                keys = [PSCustomObject]@{
                    primaryMasterKey = [PsCustomObject]@{
                        generationTime = If($null -ne $InputObject.properties.PsObject.Properties.Item('keysMetadata') -and $InputObject.properties.keysMetadata){$InputObject.properties.keysMetadata.primaryMasterKey.generationTime}Else{$null};
                        lastRotatedInDays = $null;
                    };
                    secondaryMasterKey = [PsCustomObject]@{
                        generationTime = If($null -ne $InputObject.properties.PsObject.Properties.Item('keysMetadata') -and $InputObject.properties.keysMetadata){$InputObject.properties.keysMetadata.secondaryMasterKey.generationTime}Else{$null};
                        lastRotatedInDays = $null;
                    };
                    primaryReadonlyMasterKey = [PsCustomObject]@{
                        generationTime = If($null -ne $InputObject.properties.PsObject.Properties.Item('keysMetadata') -and $InputObject.properties.keysMetadata){$InputObject.properties.keysMetadata.primaryReadonlyMasterKey.generationTime}Else{$null};
                        lastRotatedInDays = $null;
                    };
                    secondaryReadonlyMasterKey = [PsCustomObject]@{
                        generationTime = If($null -ne $InputObject.properties.PsObject.Properties.Item('keysMetadata') -and $InputObject.properties.keysMetadata){$InputObject.properties.keysMetadata.secondaryReadonlyMasterKey.generationTime}Else{$null};
                        lastRotatedInDays = $null;
                    };
                };
                networking = [PSCustomObject]@{
                    publicNetworkAccess = $InputObject.properties | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore
                    networkAclBypass = $InputObject.properties | Select-Object -ExpandProperty networkAclBypass -ErrorAction Ignore
                    ipRules = $InputObject.properties| Select-Object -ExpandProperty ipRules -ErrorAction Ignore
                    virtualNetworkRules = $InputObject.properties | Select-Object -ExpandProperty virtualNetworkRules -ErrorAction Ignore
                    privateEndpointConnections = $null;
                    networkSecurityPerimeterConfigurations = $null;
                    privateLinkResources = $null;
                };
                sqlDatabases = [System.Collections.Generic.List[System.Object]]::new();
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                locks = $null;
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $CDBObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = $_;
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('CosmosDBObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "CosmosDBObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
