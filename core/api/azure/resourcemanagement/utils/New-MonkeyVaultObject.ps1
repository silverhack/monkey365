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

Function New-MonkeyVaultObject {
<#
        .SYNOPSIS
		Create a new keyvault object

        .DESCRIPTION
		Create a new keyvault object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyVaultObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="keyvault object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $KeyVaultObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                sku = $InputObject.properties.sku;
                tenantId = $InputObject.properties.tenantId;
                provisioningState = $InputObject.properties.provisioningState;
                properties = $InputObject.properties;
                enableRbacAuthorization = if($null -ne $InputObject.Psobject.Properties.Item('enableRbacAuthorization')){$InputObject.properties.enableRbacAuthorization}else{$false};
                locks = $null;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                privateEndpointConnections = if($null -ne $InputObject.properties.PsObject.Properties.Item('privateEndpointConnections')){$InputObject.properties.privateEndpointConnections}else{$null};
                allowAccessFromAllNetworks = $null;
                networkAcls = if($null -ne $InputObject.properties.PsObject.Properties.Item('networkAcls')){$InputObject.properties.networkAcls}else{$null};
                protection = [PSCustomObject]@{
                    enablePurgeProtection = If($null -ne $InputObject.Properties.PsObject.Properties.Item('enablePurgeProtection')){$InputObject.Properties.enablePurgeProtection}Else{$false};
                    softDeleteEnabled = if($null -ne $InputObject.properties.PsObject.Properties.Item('enableSoftDelete')){$InputObject.properties.enableSoftDelete}else{$false};
                };
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                objects = [PSCustomObject]@{
                    keys = $null;
                    secrets = $null;
                    certificates = $null;
                };
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $KeyVaultObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Keyvault");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('KeyvaultObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "KeyvaultObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
