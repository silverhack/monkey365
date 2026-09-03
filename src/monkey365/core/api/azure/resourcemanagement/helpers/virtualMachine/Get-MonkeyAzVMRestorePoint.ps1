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

Function Get-MonkeyAzVMRestorePoint {
    <#
        .SYNOPSIS
		Get Azure VM restore point

        .DESCRIPTION
		Get Azure VM restore point


        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMRestorePoint
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = '2021-03-01'
    )
    Process{
        Try{
            #Set array
		    $restorePoints = [System.Collections.Generic.List[System.Object]]::new()
            $q = ('resources\n| where type =~ \"microsoft.compute/restorepointcollections\"\n | where properties.source.id =~ \"{0}\"\n| project id,\nlocation,\nname,\ntype,\nproperties' -f $InputObject.id);
            $data = @{
                subscriptions = @($O365Object.auth_tokens.ResourceManager.SubscriptionId);
                query = $q;
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
            $response = Get-MonkeyAzObjectById @p
            If($null -ne $response -and $response.Count -gt 0){
                ForEach($rp in $response.data){
                    [void]$restorePoints.Add($rp);
                }
            }
            #return Object
            Write-Output $restorePoints -NoEnumerate
        }
        Catch{
            Write-Verbose $_
        }
    }
}
