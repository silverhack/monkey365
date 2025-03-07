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

Function New-MonkeyPublicIpObject {
<#
        .SYNOPSIS
		Create a new public IP object

        .DESCRIPTION
		Create a new public IP object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyPublicIpObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Public IP object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $PublicIPObject = [ordered]@{
                id = $InputObject.Id;
		        name = $InputObject.Name;
                location = $InputObject.location;
                sku = $InputObject.sku;
                ipAddress = if($null -ne $InputObject.properties.Psobject.Properties.Item('ipAddress')){$InputObject.properties.ipAddress}else{$null};
                ipAddressVersion = $InputObject.properties.publicIPAddressVersion;
                publicIPAllocationMethod = $InputObject.properties.publicIPAllocationMethod;
		        tags = $InputObject.properties.ipTags;
                type = if($null -ne $InputObject.Psobject.Properties.Item('type')){$InputObject.type}else{$null};
                properties = $InputObject.properties;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                locks = $null;
                associatedTo = if($null -ne $InputObject.properties.Psobject.Properties.Item('ipConfiguration')){$InputObject.properties.ipConfiguration}else{$null};
                resourceGuid = if($null -ne $InputObject.properties.Psobject.Properties.Item('resourceGuid')){$InputObject.properties.resourceGuid}else{$null};
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
            $_obj = New-Object -TypeName PsObject -Property $PublicIPObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Public IP Address");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('PublicIPObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "PublicIPObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}

