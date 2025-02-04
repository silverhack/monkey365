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

Function New-MonkeyDiskObject {
<#
        .SYNOPSIS
		Create a new disk object

        .DESCRIPTION
		Create a new disk object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyDiskObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Disk object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $DiskObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                type = $InputObject.type;
                location = $InputObject.location;
                resourceGroupName = $InputObject.Id.Split("/")[4];
		        tags = if($null -ne $InputObject.Psobject.Properties.Item('tags')){$InputObject.tags}else{$null};
                managedBy = if($null -ne $InputObject.Psobject.Properties.Item('managedBy')){$InputObject.managedBy}else{$null};
                sku = $InputObject.sku;
                osType = $InputObject.properties.osType;
                disksize = $InputObject.Properties.diskSizeGB;
                timecreated = $InputObject.Properties.timeCreated;
                provisioningState = $InputObject.Properties.provisioningState;
                diskState = $InputObject.Properties.diskState;
                dataAccessAuthMode = $null;
                properties = $InputObject.properties;
                allowAccessFromAllNetworks = If($InputObject.properties.publicNetworkAccess.ToLower() -eq 'enabled'){$True}else{$false};
                networkAccessPolicy = $InputObject.properties.networkAccessPolicy;
                encryption = [PSCustomObject]@{
                    osDiskEncryption = $null;
                    sseEncryption = $InputObject.Properties.encryption.type;
                };
                locks = $null;
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $DiskObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Disk object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('DiskObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "DiskObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}

