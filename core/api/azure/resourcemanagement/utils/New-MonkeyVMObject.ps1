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

Function New-MonkeyVMObject {
<#
        .SYNOPSIS
		Create a new VM object

        .DESCRIPTION
		Create a new VM object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyVMObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $VMObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                vmSize = $InputObject.properties.hardwareProfile.vmSize;
                properties = $InputObject.properties;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                resources = if($null -ne $InputObject.Psobject.Properties.Item('resources')){$InputObject.resources}else{$null};
                isAVAgentInstalled = $null;
                isVMAgentInstalled = $null;
                instanceView = $InputObject.properties.instanceView;
                locks = $null;
                osDisk = [PSCustomObject]@{
                    isManagedDisk = $null;
                    isEncrypted = $null;
                    disk = $null;
                    SSE = [PSCustomObject]@{
                        type = $null;
                        properties = $null;
                    };
                    rawObject = $InputObject.properties.storageProfile.osDisk;
                };
                dataDisks = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
                automaticUpdates = [PSCustomObject]@{
                    enabled = $null;
                    rawObject = $null;
                };
                localNic = [PSCustomObject]@{
                    name = $null;
                    localIpAddress = $null;
                    macAddress = $null;
                    ipForwardingEnabled = $null;
                    rawObject = $null;
                };
                publicNic = [PSCustomObject]@{
                    publicIpAddress = $null;
                    publicIPAllocationMethod = $null;
                    rawObject = $null;
                };
                diagnosticSettings = [PSCustomObject]@{
                    enabled = $false;
                    name = $null;
                    id = $null;
                    properties = $null;
                    rawData = $null;
                };
                updates = $null;
                latestPatchResults = $null;
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $VMObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "VM object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('VMObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "VMObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}