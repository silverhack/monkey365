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


function Get-MonkeyAZKeyVaultInfo {
<#
        .SYNOPSIS
		Azure plugin to get all keyvaults in subscription

        .DESCRIPTION
		Azure plugin to get all keyvaults in subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZKeyVaultInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	Begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00028";
			Provider = "Azure";
			Resource = "KeyVault";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAZKeyVaultInfo";
			ApiType = "resourceManagement";
			Title = "Plugin to get Azure Keyvault information";
			Group = @("KeyVault");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Config
		$keyvault_Config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureKeyVault" } | Select-Object -ExpandProperty resource
		#Get Keyvaults
		$KeyVaults = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.KeyVault/*' }
        #Set list
        $all_keyvault = New-Object System.Collections.Generic.List[System.Object]
	}
	Process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure KeyVault",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureKeyVaultInfo');
		}
		Write-Information @msg
		if ($KeyVaults) {
			foreach ($keyvault in $KeyVaults) {
                $p = @{
                    KeyVault = $keyvault;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
                }
                $new_keyVault = Get-MonkeyAzKeyVault @p
                if($new_keyVault){
                    [void]$all_keyvault.Add($new_keyVault);
                }
            }
		}
	}
	End {
		if ($all_keyvault) {
			$all_keyvault.PSObject.TypeNames.Insert(0,'Monkey365.Azure.KeyVault')
			[pscustomobject]$obj = @{
				Data = $all_keyvault;
				Metadata = $monkey_metadata;
			}
			$returnData.az_keyvault = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure KeyVaults",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureKeyVaultsEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




