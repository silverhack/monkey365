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


function Get-MonkeyAZNetworkSecurityGroup {
<#
        .SYNOPSIS
		Collector to get Network Security Rules from Azure

        .DESCRIPTION
		Collector to get Network Security Rules from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZNetworkSecurityGroup
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
			Id = "az00021";
			Provider = "Azure";
			Resource = "Firewall";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAZNetworkSecurityGroup";
			ApiType = "resourceManagement";
			description = "Collector to get Network Security Rules from Azure";
			Group = @(
				"Firewall";
				"NetworkSecurityGroup"
			);
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/";
			ruleSuffixes = @(
				"az_nsg_rules"
			);
			dependsOn = @(

			);
		}
		#Get Config
		$AzureNSGConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureNSG" } | Select-Object -ExpandProperty resource
		#Get Network Security Groups
		$all_nsgs = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.Network/networkSecurityGroups' }
		if (-not $all_nsgs) { continue }
		#Set array
		$all_nsg_rules = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Azure Network Security Groups",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzureNSGInfo');
		}
		Write-Information @msg
		if ($all_nsgs) {
			foreach ($my_nsg in $all_nsgs) {
				$msg = @{
					MessageData = ($message.AzureUnitResourceMessage -f $my_nsg.Name,"Network Security Group");
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $InformationAction;
					Tags = @('AzureNSGInfo');
				}
				Write-Information @msg
				#Set query
				$p = @{
					Id = $my_nsg.Id;
					APIVersion = $AzureNSGConfig.api_version;
					Verbose = $O365Object.Verbose;
					Debug = $O365Object.Debug;
					InformationAction = $O365Object.InformationAction;
				}
				$nsg = Get-MonkeyAzObjectById @p
				if ($nsg) {
					$msg = @{
						MessageData = ($message.MonkeyResponseCountMessage -f $nsg.Properties.securityrules.Count);
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzureNSGInfo');
					}
					Write-Information @msg
					#iterate over properties
					foreach ($sr in $nsg.Properties.securityrules) {
						$SecurityRule = New-Object -TypeName PSCustomObject
						$SecurityRule | Add-Member -Type NoteProperty -Name name -Value $nsg.Name
						$SecurityRule | Add-Member -Type NoteProperty -Name location -Value $nsg.location
						$SecurityRule | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $nsg.Id.Split("/")[4]
						#Getting interfaces names
						$AllInterfaces = @()
						foreach ($interface in $nsg.Properties.networkinterfaces) {
							$Ifacename = $interface.Id.Split("/")[8]
							$AllInterfaces += $Ifacename
						}
						if ($AllInterfaces) {
							$SecurityRule | Add-Member -Type NoteProperty -Name RulesAppliedOn -Value (@($AllInterfaces) -join ',')
						}
						$SecurityRule | Add-Member -Type NoteProperty -Name Rulename -Value $sr.Name
						$SecurityRule | Add-Member -Type NoteProperty -Name RuleDescription -Value $sr.Properties.description
						$SecurityRule | Add-Member -Type NoteProperty -Name Protocol -Value $sr.Properties.protocol
						$SecurityRule | Add-Member -Type NoteProperty -Name SourcePortRange -Value $sr.Properties.sourcePortRange
						$SecurityRule | Add-Member -Type NoteProperty -Name SourcePortRanges -Value (@($sr.Properties.sourcePortRanges) -join ',')
						$SecurityRule | Add-Member -Type NoteProperty -Name DestinationPortRange -Value $sr.Properties.DestinationPortRange
						$SecurityRule | Add-Member -Type NoteProperty -Name DestinationPortRanges -Value (@($sr.Properties.DestinationPortRanges) -join ',')
						$SecurityRule | Add-Member -Type NoteProperty -Name SourceAddressPrefix -Value $sr.Properties.sourceAddressPrefix
						$SecurityRule | Add-Member -Type NoteProperty -Name SourceAddressPrefixes -Value (@($sr.Properties.sourceAddressPrefixes) -join ',')
						$SecurityRule | Add-Member -Type NoteProperty -Name DestinationAddressPrefix -Value $sr.Properties.DestinationAddressPrefix
						$SecurityRule | Add-Member -Type NoteProperty -Name DestinationAddressPrefixes -Value (@($sr.Properties.DestinationAddressPrefixes) -join ',')
						$SecurityRule | Add-Member -Type NoteProperty -Name Access -Value $sr.Properties.access
						$SecurityRule | Add-Member -Type NoteProperty -Name Priority -Value $sr.Properties.priority
						$SecurityRule | Add-Member -Type NoteProperty -Name direction -Value $sr.Properties.direction
						$SecurityRule | Add-Member -Type NoteProperty -Name rawObject -Value $sr
						#Add to array
						$all_nsg_rules += $SecurityRule
					}
					#Getting all default security rules
					foreach ($dsr in $nsg.Properties.defaultSecurityRules) {
						$DefaultSecurityRule = New-Object -TypeName PSCustomObject
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name name -Value $nsg.Name
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name location -Value $nsg.location
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $nsg.Id.Split("/")[4]
						#Getting interfaces names
						$AllInterfaces = @()
						foreach ($interface in $nsg.Properties.networkinterfaces) {
							$Ifacename = $interface.Id.Split("/")[8]
							$AllInterfaces += $Ifacename
						}
						if ($AllInterfaces) {
							$DefaultSecurityRule | Add-Member -Type NoteProperty -Name RulesAppliedOn -Value (@($AllInterfaces) -join ',')
						}
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name Rulename -Value $dsr.Name
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name RuleDescription -Value $dsr.Properties.description
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name Protocol -Value $dsr.Properties.protocol
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name SourcePortRange -Value $dsr.Properties.sourcePortRange
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name DestinationPortRange -Value $dsr.Properties.DestinationPortRange
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name SourceAddressPrefix -Value $dsr.Properties.sourceAddressPrefix
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name DestinationAddressPrefix -Value $dsr.Properties.DestinationAddressPrefix
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name Access -Value $dsr.Properties.access
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name Priority -Value $dsr.Properties.priority
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name direction -Value $dsr.Properties.direction
						$DefaultSecurityRule | Add-Member -Type NoteProperty -Name rawObject -Value $dsr

						$all_nsg_rules += $DefaultSecurityRule
					}
				}
			}
		}
	}
	end {
		if ($all_nsg_rules) {
			$all_nsg_rules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkSecurityRules')
			[pscustomobject]$obj = @{
				Data = $all_nsg_rules;
				Metadata = $monkey_metadata;
			}
			$returnData.az_nsg_rules = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Security Rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AzureNSGEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}







