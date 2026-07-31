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


function Get-MonkeyAzResourceGraphMetadata {
<#
        .SYNOPSIS
		Collector to get information about resources within a subscription

        .DESCRIPTION
		Collector to get information about resources within a subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceGraphMetadata
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns","",Scope = "Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	Begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00164";
			Provider = "Azure";
			Resource = "Subscription";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzResourceGraphMetadata";
			ApiType = "resourceManagement";
			description = "Collector to get information about resources within a subscription";
			Group = @(
				"Subscription"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_resources"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$all_resources = [System.Collections.Generic.List[System.Object]]::new()
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Resources",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureResourcesInfo');
		}
		Write-Information @msg
        #Get resources info
        If($null -ne $O365Object.filterByResourceGroups){
            ForEach($rsrc in @($O365Object.filterByResourceGroups)){
                $query = ("Resources | project id, name, sku, type, location, resourceGroup | where resourceGroup == '{0}'" -f $rsrc);
                $data = Get-MonkeyAzResourceGraphObject -query $query
                If($null -ne $data){
                    If ($data -is [System.Collections.IEnumerable] -and $data -isnot [string]){
                        [void]$all_resources.AddRange($data)
                    }
                    ElseIf ($data.GetType() -eq [System.Management.Automation.PSCustomObject] -or $data.GetType() -eq [System.Management.Automation.PSObject]) {
                        [void]$all_resources.Add($data)
                    }
                }
            }
        }
        Else{
            $query = "Resources | project id, name, sku, type, location, resourceGroup";
            $data = Get-MonkeyAzResourceGraphObject -query $query
            If($null -ne $data){
                If ($data -is [System.Collections.IEnumerable] -and $data -isnot [string]){
                    [void]$all_resources.AddRange($data)
                }
                ElseIf ($data.GetType() -eq [System.Management.Automation.PSCustomObject] -or $data.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$all_resources.Add($data)
                }
            }
        }
        #return object
        If ($all_resources.Count -gt 0) {
			$all_resources.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Resources')
			[pscustomobject]$obj = @{
				Data = $all_resources;
				Metadata = $monkey_metadata;
			}
			$returnData.az_resources = $obj;
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Resources",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureSubscriptionEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}