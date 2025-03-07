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


function Get-MonkeyAADRMRbac {
<#
        .SYNOPSIS
		Collector to get information about RBAC from AADRM

        .DESCRIPTION
		Collector to get information about RBAC from AADRM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADRMRbac
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
		#Get Access Token from AADRM
		#Collector metadata
		$monkey_metadata = @{
			Id = "aadrm07";
			Provider = "Microsoft365";
			Resource = "IRM";
			ResourceType = $null;
			resourceName = $null;
			collectorName = "Get-MonkeyAADRMRbac";
			ApiType = $null;
			description = "Collector to get information about RBAC from AADRM";
			Group = @(
				"Purview";
				"ExchangeOnline"
			);
			Tags = @(

			);
			references = @(
				"https://silverhack.github.io/monkey365/"
			);
			ruleSuffixes = @(
				"o365_aadrm_rbac"
			);
			dependsOn = @(

			);
			enabled = $true;
			supportClientCredential = $true
		}
		$access_token = $O365Object.auth_tokens.AADRM
		#Get AADRM Url
		$url = $O365Object.Environment.aadrm_service_locator
		if ($null -ne $access_token) {
			#Set Authorization Header
			$AuthHeader = ("MSOID {0}" -f $access_token.AccessToken)
			$requestHeader = @{ "Authorization" = $AuthHeader }
		}
		#Create AADRM object
		$aadrm_rbac = New-Object -TypeName PSCustomObject
	}
	process {
		if ($requestHeader -and $url) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $collectorId,"Office 365 Rights Management: RBAC users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('AADRMRBACStatus');
			}
			Write-Information @msg
			$url_global = ("{0}/Administrators/Roles/GlobalAdministrator" -f $url)
			$params = @{
				url = $url_global;
				Method = 'Get';
				ContentType = 'application/json; charset=utf-8';
				Headers = $requestHeader;
				disableSSLVerification = $true;
				InformationAction = $O365Object.InformationAction;
				Verbose = $O365Object.Verbose;
				Debug = $O365Object.Debug;
			}
			#call AADRM endpoint
			$AADRM_Global_Admins = Invoke-MonkeyWebRequest @params
			if ($AADRM_Global_Admins) {
				$aadrm_rbac | Add-Member -Type NoteProperty -Name Global_Admins -Value $AADRM_Global_Admins
			}
			else {
				$aadrm_rbac | Add-Member -Type NoteProperty -Name Global_Admins -Value $false
			}
			#Get Connector admins
			$url_connector = ("{0}/Administrators/Roles/ConnectorAdministrator" -f $url)
			$params = @{
				url = $url_connector;
				Method = 'Get';
				ContentType = 'application/json; charset=utf-8';
				Headers = $requestHeader;
				disableSSLVerification = $true;
			}
			#call AADRM endpoint
			$AADRM_Connector_Admins = Invoke-MonkeyWebRequest @params
			if ($AADRM_Connector_Admins) {
				$aadrm_rbac | Add-Member -Type NoteProperty -Name Connector_Admins -Value $AADRM_Connector_Admins
			}
			else {
				$aadrm_rbac | Add-Member -Type NoteProperty -Name Connector_Admins -Value $false
			}
		}
	}
	end {
		if ($aadrm_rbac) {
			$aadrm_rbac.PSObject.TypeNames.Insert(0,'Monkey365.AADRM.RBAC')
			[pscustomobject]$obj = @{
				Data = $aadrm_rbac;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_aadrm_rbac = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Office 365 Rights Management RBAC users",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AADRMRBACEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}










