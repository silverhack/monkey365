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

Function New-MonkeyVMPatchObject {
<#
        .SYNOPSIS
		Create a new VM patch object

        .DESCRIPTION
		Create a new VM patch object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyVMPatchObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="VM Patch object")]
        [Object]$InputObject
    )
    Process{
        try{
            $vmPatchObj = [ordered]@{
                Id = $InputObject.Id;
                type = $InputObject.type;
                tenantId = $InputObject.tenantId;
                kind = $InputObject.kind;
                location = $InputObject.location;
                resourceGroup = $InputObject.resourceGroup;
                subscriptionId = $InputObject.subscriptionId;
                managedBy = $InputObject.managedBy;
                sku = $InputObject.sku;
                tags = $InputObject.tags;
                identity = $InputObject.identity;
                extendedLocation = $InputObject.extendedLocation;
                lastModifiedDateTime = $InputObject.properties.lastModifiedDateTime;
                classifications = $InputObject.properties.classifications;
                patchName = $InputObject.properties.patchName;
                patchId = $InputObject.properties.patchId;
                publishedDateTime = $InputObject.properties.publishedDateTime;
                rebootBehavior = $InputObject.properties.rebootBehavior;
                kbId = $InputObject.properties.kbId;
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $vmPatchObj
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "VM Patch object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('VMPatchObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "VMPatchObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
