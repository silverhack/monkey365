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

Function New-MonkeyAIHubCognitiveAccountObject {
<#
        .SYNOPSIS
		Create a new AI Hub Cognitive object

        .DESCRIPTION
		Create a new AI Hub Cognitive object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyAIHubCognitiveAccountObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="AI Hub Cognitive Account object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $AIHubObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                location = $InputObject.location;
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                type = $InputObject.type;
                sku = $InputObject.sku;
                kind = $InputObject.kind;
                provisioningState = $InputObject.properties.provisioningState;
                createdTime = $InputObject.properties.dateCreated;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                properties = $InputObject.properties;
                locks = $null;
                cmkEncryption = $null;
                disableLocalAuth = if($null -ne $InputObject.properties.Psobject.Properties.Item('disableLocalAuth')){$InputObject.properties.disableLocalAuth}else{$false};
                identity = if($null -ne $InputObject.Psobject.Properties.Item('identity')){$InputObject.identity}else{$null};
                networkAcls = if($null -ne $InputObject.properties.Psobject.Properties.Item('networkAcls')){$InputObject.properties.networkAcls}else{$null};
                privateEndpoints = if($null -ne $InputObject.properties.Psobject.Properties.Item('privateEndpointConnections')){$InputObject.properties.privateEndpointConnections}else{$null};
                publicNetworkAccess = if($null -ne $InputObject.properties.Psobject.Properties.Item('publicNetworkAccess')){$InputObject.properties.publicNetworkAccess}else{"Enabled"};
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
            $_obj = New-Object -TypeName PsObject -Property $AIHubObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "AI Hub object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AIHubObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "AIHubObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
