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


function Get-MonkeyAADRMServiceSuperUser {
<#
        .SYNOPSIS
		Plugin to get information about superuser in AADRM

        .DESCRIPTION
		Plugin to get information about superuser in AADRM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADRMServiceSuperUser
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
		#Get Access Token from AADRM
		#Plugin metadata
		$monkey_metadata = @{
			Id = "aadrm09";
			Provider = "Microsoft365";
			Resource = "IRM";
			ResourceType = $null;
			resourceName = $null;
			PluginName = "Get-MonkeyAADRMServiceSuperUser";
			ApiType = $null;
			Title = "Plugin to get information about superuser in AADRM";
			Group = @("Purview","ExchangeOnline");
			Tags = @{
				"enabled" = $true
			};
			Docs = "https://silverhack.github.io/monkey365/"
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
		$aadrm_feature_status = New-Object -TypeName PSCustomObject
	}
	process {
		if ($requestHeader -and $url) {
			$msg = @{
				MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Office 365 Rights Management: Service Super user state",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('AADRMSuperUserStatus');
			}
			Write-Information @msg
			$url = ("{0}/SuperUserState" -f $url)
			$params = @{
				Url = $url;
				Method = 'Get';
				ContentType = 'application/json; charset=utf-8';
				Headers = $requestHeader;
				disableSSLVerification = $true;
			}
			#call AADRM endpoint
			$aadrm_srv_super_user = Invoke-MonkeyWebRequest @params
			if ($null -ne $aadrm_srv_super_user -and $aadrm_srv_super_user -eq '0') {
				$aadrm_feature_status | Add-Member -Type NoteProperty -Name status -Value "Disabled"
			}
			else {
				$aadrm_feature_status | Add-Member -Type NoteProperty -Name status -Value $aadrm_srv_super_user
			}
		}
	}
	end {
		if ($aadrm_feature_status) {
			$aadrm_feature_status.PSObject.TypeNames.Insert(0,'Monkey365.AADRM.SuperUser')
			[pscustomobject]$obj = @{
				Data = $aadrm_feature_status;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_aadrm_super_user = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Office 365 Rights Management SuperUser status",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = "verbose";
				InformationAction = $O365Object.InformationAction;
				Tags = @('AADRMSuperUserEmptyResponse');
				Verbose = $O365Object.Verbose;
			}
			Write-Verbose @msg
		}
	}
}




