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
                id = $InputObject | Select-Object -ExpandProperty Id -ErrorAction Ignore;
		        name = $InputObject | Select-Object -ExpandProperty Name -ErrorAction Ignore;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore;
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore;
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                kind = $InputObject | Select-Object -ExpandProperty kind -ErrorAction Ignore;
                sku = $InputObject.properties | Select-Object -ExpandProperty sku -ErrorAction Ignore;
                tenantId = $InputObject.properties | Select-Object -ExpandProperty tenantId -ErrorAction Ignore;
                provisioningState = $InputObject.properties | Select-Object -ExpandProperty provisioningState -ErrorAction Ignore;
                enableRbacAuthorization = if($null -ne $InputObject.Psobject.Properties.Item('enableRbacAuthorization')){$InputObject.properties.enableRbacAuthorization}else{$false};
                locks = $null;
                networking = [PSCustomObject]@{
                    bypassAzureServices = $InputObject.properties.networkAcls.bypass -match 'AzureServices';
                    allowAccessFromAllNetworks = if ($InputObject.properties.networkAcls.virtualNetworkRules.Count -eq 0 -and $InputObject.properties.networkAcls.ipRules.Count -eq 0 -and $InputObject.properties.networkAcls.defaultAction -eq 'Allow'){$true}else{$false};
                    publicNetworkAccess = $InputObject.properties | Select-Object -ExpandProperty publicNetworkAccess -ErrorAction Ignore
                    networkAclBypass = $InputObject.properties.networkAcls | Select-Object -ExpandProperty bypass -ErrorAction Ignore
                    ipRules = $InputObject.properties.networkAcls| Select-Object -ExpandProperty ipRules -ErrorAction Ignore
                    virtualNetworkRules = $InputObject.properties.networkAcls | Select-Object -ExpandProperty virtualNetworkRules -ErrorAction Ignore
                    subnet = $InputObject.properties.networkAcls.virtualNetworkRules | Select-Object -ExpandProperty id -ErrorAction Ignore
                    privateEndpointConnections = $InputObject.properties | Select-Object -ExpandProperty privateEndpointConnections -ErrorAction Ignore ;
                    networkSecurityPerimeterConfigurations = $null;
                    privateLinkResources = $null;
                };
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
