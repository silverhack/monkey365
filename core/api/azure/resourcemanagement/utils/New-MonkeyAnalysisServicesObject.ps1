﻿# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
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

Function New-MonkeyAnalysisServicesObject {
<#
        .SYNOPSIS
		Create a new Analysis Services object

        .DESCRIPTION
		Create a new Analysis Services object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyAnalysisServicesObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Analysis Services object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $AnServicesObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
                sku = $InputObject.sku;
                resourceGroupName = $InputObject.Id.Split("/")[4];
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                provisioningState = $InputObject.Properties.provisioningState;
                state = $InputObject.Properties.state;
                properties = $InputObject.properties;
                firewallEnabled = if($null -ne $InputObject.properties.Psobject.Properties.Item('ipV4FirewallSettings') -and $InputObject.properties.ipV4FirewallSettings.firewallRules.Count -gt 0){$True}else{$false};
                backupEnabled = if($null -ne $InputObject.properties.Psobject.Properties.Item('backupBlobContainerUri') -and $null -ne $InputObject.properties.backupBlobContainerUri){$True}else{$false};
                firewall = if($null -ne $InputObject.properties.Psobject.Properties.Item('ipV4FirewallSettings')){$InputObject.properties.ipV4FirewallSettings}else{$null};
                backup = if($null -ne $InputObject.properties.Psobject.Properties.Item('backupBlobContainerUri')){$InputObject.properties.backupBlobContainerUri}else{$null};
                locks = $null;
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $AnServicesObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Analysis Services object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AnalysisServicesObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "AnalysisServicesObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
