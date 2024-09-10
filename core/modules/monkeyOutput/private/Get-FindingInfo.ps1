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

Function Get-FindingInfo{
    <#
        .SYNOPSIS
        Get finding info object
        .DESCRIPTION
        Get finding info object
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-FindingInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Level")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Tenant Id")]
        [String]$TenantId
    )
    Process{
        Try{
            $findingInfoObject = New-OcsfFindingInfoObject
            if($null -ne $findingInfoObject){
                ##Populate Finding Info##
                $findingInfoObject.CreatedTime = $InputObject.timestamp;
                $findingInfoObject.Description = $InputObject.description | Convert-MarkDownToPlainText | Remove-TabAndNewLine;
                $findingInfoObject.ProductId = 'Monkey365';
                $findingInfoObject.Title = $InputObject.displayName;
                $findingInfoObject.Id = ("Monkey365-{0}-{1}-{2}" -f $InputObject.idSuffix.Replace('_','-'), $TenantId.Replace('-',''), (New-RandomId));
                #return Object
                return $findingInfoObject;
            }
        }
        Catch{
            Write-Error $_
        }
    }
}