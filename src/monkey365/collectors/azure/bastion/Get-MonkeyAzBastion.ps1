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


function Get-MonkeyAzBastion {
<#
        .SYNOPSIS
		Collector to get Bastions from Azure

        .DESCRIPTION
		Collector to get Bastions from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzBastion
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Collector ID")]
		[string]$collectorId
	)
	begin {
		#Collector metadata
		$monkey_metadata = @{
			Id = "az00015";
			Provider = "Azure";
			Resource = "Bastion";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAzBastion";
			ApiType = "resourceManagement";
			description = "Collector to get information about Azure Bastion";
			Group = @();
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_bastions"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$config = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "bastionHost" } | Select-Object -ExpandProperty resource
		#Get bastions
		$bastions = $O365Object.all_resources.Where({ $_.type -like '*Microsoft.Network/bastionHosts*' })
        #Set array
        $all_bastions = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
	}
	process {
        If($bastions.Count -eq 0){
		    $msg = @{
			    MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Bastion",$O365Object.current_subscription.displayName);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('AzureBastionInfo');
		    }
		    Write-Information @msg
            ForEach($_host in $bastions.GetEnumerator()){
                $p = @{
			        Id = $_host.Id;
                    ApiVersion = $config.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $bastion = Get-MonkeyAzObjectById @p
                If($bastion){
                    [void]$all_bastions.Add($bastion);
                }
            }
        }
	}
	End {
		If ($all_bastions) {
			$all_bastions.PSObject.TypeNames.Insert(0,'Monkey365.Azure.Bastion')
			[pscustomobject]$obj = @{
				Data = $all_bastions;
				Metadata = $monkey_metadata;
			}
			$returnData.az_bastions = $obj
		}
		Else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Bastion",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureBastionEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}









