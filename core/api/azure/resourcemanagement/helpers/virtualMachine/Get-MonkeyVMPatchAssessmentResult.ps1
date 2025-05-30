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

function Get-MonkeyVMPatchAssessmentResult{
    <#
        .SYNOPSIS
        Get VM patch assessment result from Azure

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyVMPatchAssessmentResult
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-10-01"
    )
    Process{
        #Set array
		$patchAssessmentResults = [System.Collections.Generic.List[System.Object]]::new()
        $query = ("PatchAssessmentResources | where type =~ 'Microsoft.Compute/virtualMachines/patchAssessmentResults' and id =~ '{0}/patchAssessmentResults/latest'\n" -f $InputObject.Id);
        #Data object
        $data = @{
            subscriptions = @($O365Object.auth_tokens.ResourceManager.SubscriptionId);
            query = $query;
        } | ConvertTo-Json -Depth 10 -Compress | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        $p = @{
            Resource = '/providers/Microsoft.ResourceGraph/resources';
            Method = 'POST';
            Data = $data;
            ApiVersion = $APIVersion;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		$patchResult = Get-MonkeyAzObjectById @p
        if($patchResult){
            foreach($status in $patchResult.data.GetEnumerator()){
                [void]$patchAssessmentResults.Add($status.properties);
            }
        }
        #return obj
        Write-Output $patchAssessmentResults -NoEnumerate
    }
}
