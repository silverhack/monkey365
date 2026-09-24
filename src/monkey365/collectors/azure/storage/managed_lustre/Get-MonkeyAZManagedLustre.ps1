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

function Get-MonkeyAZManagedLustre {
<#
        .SYNOPSIS
		Collector to extract metadata from Azure managed Lustre

        .DESCRIPTION
		Collector to extract metadata from Azure managed Lustre

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZManagedLustre
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
			Id = "az00039";
			Provider = "Azure";
			Resource = "StorageAccounts";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "MonkeyAZManagedLustre";
			ApiType = "resourceManagement";
			description = "Collector to extract metadata from Azure managed Lustre";
			Group = @(
				"StorageAccounts"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"az_managed_lustre"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		#Get Config
		$lustreConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "managedLustre" } | Select-Object -ExpandProperty resource
		#Get manage Lustre objects
        $managed_lustre = $O365Object.all_resources.Where({$_.type -match '^Microsoft\.StorageCache/amlFilesystems$'});
		#Set null
		$all_managed_lustre = $null
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure managed lustre",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $O365Object.InformationAction;
			Tags = @('AzureManagedLustreInfo');
		}
		Write-Information @msg
		#Check manage lustre
		If ($managed_lustre.Count -gt 0) {
			$new_arg = @{
				APIVersion = $lustreConfig.api_version;
			}
			$p = @{
				ScriptBlock = { Get-MonkeyAzStorageManagedLustreInfo -InputObject $_ };
				Arguments = $new_arg;
				Runspacepool = $O365Object.monkey_runspacePool;
				ReuseRunspacePool = $true;
				Debug = $O365Object.VerboseOptions.Debug;
				Verbose = $O365Object.VerboseOptions.Verbose;
				MaxQueue = $O365Object.MaxQueue;
				BatchSleep = $O365Object.BatchSleep;
				BatchSize = $O365Object.BatchSize;
			}
			$all_managed_lustre = $managed_lustre | Invoke-MonkeyJob @p
            If ($all_managed_lustre) {
			    $all_managed_lustre.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ManagedLustre')
			    [pscustomobject]$obj = @{
				    Data = $all_managed_lustre;
				    Metadata = $monkey_metadata;
			    }
			    $returnData.az_managed_lustre = $obj
		    }
            Else {
			    $msg = @{
				    MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure managed Lustre",$O365Object.current_subscription.displayName);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = "verbose";
				    InformationAction = $O365Object.InformationAction;
				    Tags = @('AzureManagedLustreEmptyResponse');
				    Verbose = $O365Object.Verbose;
			    }
			    Write-Verbose @msg
		    }
		}
	}
}




