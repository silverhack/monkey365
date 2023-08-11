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


function Get-MonkeyEXODLPInfo {
<#
        .SYNOPSIS
		Plugin to get information about DLP compliance policies in Microsoft Exchange Online

        .DESCRIPTION
		Plugin to get information about DLP compliance policies in Microsoft Exchange Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyEXODLPInfo
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
		$exo_compliance_dlp_policies = $dlp_validations = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "purv010";
			Provider = "Microsoft365";
			Resource = "Purview";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyEXODLPInfo";
			ApiType = $null;
			Title = "Plugin to get information about DLP compliance policies in Microsoft Exchange Online";
			Group = @("Purview");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
		}
	}
	process {
		if($O365Object.onlineServices.Purview -eq $true){
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Security and Compliance DLP compliance information",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompDLPInfo');
			}
			Write-Information @msg
			$exo_compliance_dlp_policies = Get-DataLossPreventionInfo
            if ($null -ne $exo_compliance_dlp_policies) {
                $msg = @{
					MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Security and Compliance DLP analysis",$O365Object.TenantID);
					callStack = (Get-PSCallStack | Select-Object -First 1);
					logLevel = 'info';
					InformationAction = $O365Object.InformationAction;
					Tags = @('SecCompDLPInfo');
				}
				Write-Information @msg
				#Get DLP validations
				$dlp_validations = Invoke-DLPValidation -dlp_objects $exo_compliance_dlp_policies
            }
			else{
				$exo_compliance_dlp_policies = @{
					isEnabled = $false
				}
			}
		}
	}
	end {
		if ($exo_compliance_dlp_policies) {
			$exo_compliance_dlp_policies.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.DLP.Compliance.Policy')
			[pscustomobject]$obj = @{
				Data = $exo_compliance_dlp_policies;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_dlp_compliance_info = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance DLP compliance information",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompDLPEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
		#Add DLP validations
		if ($null -ne $dlp_validations) {
			$dlp_validations.PSObject.TypeNames.Insert(0,'Monkey365.SecurityCompliance.DLP.Validations')
			[pscustomobject]$obj = @{
				Data = $dlp_validations;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_secomp_dlp_analysis = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Security and Compliance DLP analysis",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('SecCompDLPEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




