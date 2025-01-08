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

Function New-GenericOutputPsObject {
<#
        .SYNOPSIS
		Create a new generic output object

        .DESCRIPTION
		Create a new generic output object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-GenericOutputPsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage="Issue object")]
        [Object]$InputObject
    )
    Process{
        Try{
            #Create ordered dictionary
            $GenericObject = [ordered]@{
                timestamp = $InputObject.timestamp;
                tenantId = $null;
                tenantName = $null;
                uniqueId = $null;
                provider = $null;
                findingId = $InputObject.idSuffix;
                findingTitle = ("`"{0}`"" -f ($InputObject.displayName | Convert-MarkDownToPlainText | Remove-TabAndNewLine));
                findingType = $null;
                findingTags = $null;
                serviceName = $InputObject.serviceType;
                severityId = $InputObject.level | Get-SeverityId;
                severity = $InputObject.level;
                findingDescription = If($InputObject.description){("`"{0}`"" -f ($InputObject.description | Convert-MarkDownToPlainText | Remove-TabAndNewLine))};
                findingRationale = If($InputObject.rationale){("`"{0}`"" -f ($InputObject.rationale | Convert-MarkDownToPlainText | Remove-TabAndNewLine))};
                findingRemediation = If($InputObject.remediation.text){("`"{0}`"" -f ($InputObject.remediation.text | Convert-MarkDownToPlainText | Remove-TabAndNewLine))};
                findingReferenceUrl = (@($InputObject.references) -join ',');
                resourceLocation = $null;
                status = $null;
                resourceType = $null;
                resourceId = $null;
                resourceName = $null;
                resourceGroup = $null;
                resourceTags = $null;
                compliance = $InputObject.compliance | Get-ObjectCompliance;
                notes = (@($InputObject.notes) -join ',');
                monkey365Version = $null;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $GenericObject
            #return object
            return $_obj
        }
        Catch{
            Write-Error $_
        }
    }
}
