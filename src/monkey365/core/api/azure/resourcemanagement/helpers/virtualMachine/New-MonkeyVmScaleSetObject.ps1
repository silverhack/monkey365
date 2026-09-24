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

Function New-MonkeyVmScaleSetObject {
<#
        .SYNOPSIS
		Create a new vm scale set object

        .DESCRIPTION
		Create a new vm scale set object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyVmScaleSetObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="VM ScaleSet object")]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $VMObject = [ordered]@{
                id = $InputObject | Select-Object -ExpandProperty Id -ErrorAction Ignore;
		        name = $InputObject | Select-Object -ExpandProperty name -ErrorAction Ignore;
                type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                location = $InputObject | Select-Object -ExpandProperty location -ErrorAction Ignore;
		        tags = $InputObject | Select-Object -ExpandProperty tags -ErrorAction Ignore;
                sku = $InputObject | Select-Object -ExpandProperty sku -ErrorAction Ignore;
                properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                resourceGroupName = $InputObject.Id.Split("/")[4];
                virtualMachineProfile = $InputObject.properties | Select-Object -ExpandProperty virtualMachineProfile -ErrorAction Ignore
                networking = [PSCustomObject]@{
                    virtualNetworks = $null;
                    subnets = $null;
                    networkSecurityGroups = $null;
                    adminSecurityRules = $null;
                    loadBalancers = $null;
                    applicationSecurityGroups = $null;
                    acceleratedNetworking = $null;
                };
                instances = $null;
                locks = $null;
                automaticUpdates = [PSCustomObject]@{
                    enabled = $null;
                    rawObject = $null;
                };
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
            $_obj = New-Object -TypeName PsObject -Property $VMObject
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Virtual Machine ScaleSet object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('VMScaleSetObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "VMScaleSetObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
