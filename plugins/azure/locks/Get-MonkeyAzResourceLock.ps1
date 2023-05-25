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


function Get-MonkeyAzResourceLock {
<#
        .SYNOPSIS
		Plugin to get management locks for a resource

        .DESCRIPTION
		Plugin to get management locks for a resource

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceLock
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00020";
			Provider = "Azure";
			Resource = "ResourceLocks";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAzResourceLock";
			ApiType = "resourceManagement";
			Title = "Plugin to get resource locks from Azure";
			Group = @("ResourceLocks","General");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Config
		$locks_config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureLocks" } | Select-Object -ExpandProperty resource
		#Set array
		$all_locks = New-Object System.Collections.Generic.List[System.Object]
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure Locks",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureLocksInfo');
		}
		Write-Information @msg
		if ($null -ne $O365Object.all_resources) {
			foreach ($resource in $O365Object.all_resources) {
				$msg = @{
					MessageData = ("Getting locks from {0}" -f $resource.Name);
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'verbose';
					InformationAction = $InformationAction;
					Tags = @('AzureLocksInfo');
				}
				Write-Verbose @msg
				#Get lock
                $p = @{
					Id = $resource.Id;
					Resource = "providers/Microsoft.Authorization/locks";
					ApiVersion = $locks_config.api_version;
					Method = "GET";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.Verbose;
                    Debug = $O365Object.debug;
				}
				$resource_lock_info = Get-MonkeyAzObjectById @p
				if ($null -ne $resource_lock_info) {
					$lock_info = [pscustomobject]@{
						Id = $resource.Id;
						Name = $resource.Name;
						SKU = $resource.SKU;
						kind = $resource.kind;
						location = $resource.location;
						locks = $resource_lock_info;
					}
					[void]$all_locks.Add($lock_info);
				}
                else{
                    $lock_info = [pscustomobject]@{
						Id = $resource.Id;
						Name = $resource.Name;
						SKU = $resource.SKU;
						kind = $resource.kind;
						location = $resource.location;
						locks = $null;
					}
					[void]$all_locks.Add($lock_info);
                }
			}
		}
	}
	end {
		if ($all_locks) {
			$all_locks.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Locks')
			[pscustomobject]$obj = @{
				Data = $all_locks;
				Metadata = $monkey_metadata;
			}
			$returnData.az_locks = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Locks",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureLocksEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




