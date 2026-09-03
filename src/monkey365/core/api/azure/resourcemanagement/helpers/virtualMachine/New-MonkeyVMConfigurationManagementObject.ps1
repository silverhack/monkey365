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

Function New-MonkeyVMConfigurationManagementObject {
<#
        .SYNOPSIS
		Create a new VM configuration management object

        .DESCRIPTION
		Create a new VM configuration management object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyVMConfigurationManagementObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="VM Configuration Management object")]
        [Object]$InputObject
    )
    Process{
        try{
            $configurationObj = [ordered]@{
                Id = $InputObject.Id;
                type = $InputObject.type;
                name = $InputObject.name;
                kind = $InputObject.kind;
                location = $InputObject.location;
                resourceGroup = $InputObject.resourceGroup;
                subscriptionId = $InputObject.subscriptionId;
                machine = $InputObject.machine;
                assignmentType = $InputObject.assignmentType;
                tags = $InputObject.tags;
                complianceState = $InputObject.complianceState;
                compliantPercentage = $InputObject.compliantPercentage;
                nonCompliantPercentage = $InputObject.nonCompliantPercentage;
                totalResourcesCount = $InputObject.totalResourcesCount;
                totalCompliantResourcesCount = $InputObject.totalCompliantResourcesCount;
                totalNonCompliantResourcesCount = $InputObject.totalNonCompliantResourcesCount;
                policyAssignmentId = $InputObject | Select-Object -ExpandProperty extendedLocation -ErrorAction Ignore
                lastModifiedDateTime = $InputObject | Select-Object -ExpandProperty lastModifiedDateTime -ErrorAction Ignore
                rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $configurationObj
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "VM Configuration Management object");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('VMConfigurationManagementObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "VMConfigurationManagementObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
