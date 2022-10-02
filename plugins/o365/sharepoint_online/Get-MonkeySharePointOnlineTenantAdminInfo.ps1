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


function Get-MonkeySharePointOnlineTenantAdminInfo {
<#
        .SYNOPSIS
		Plugin to get information about SPS Tenant information

        .DESCRIPTION
		Plugin to get information about SPS Tenant information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineTenantAdminInfo
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
		$sps_tenant_admin_details = $null
		#Plugin metadata
		$monkey_metadata = @{
			Id = "sps0008";
			Provider = "Microsoft365";
			Title = "Plugin to get information about SPS Tenant information";
			Group = @("SharepointOnline");
			ServiceName = "SharePoint Online Tenant Admin information";
			PluginName = "Get-MonkeySharePointOnlineTenantAdminInfo";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Access Token from AADRM
		$sps_auth = $O365Object.auth_tokens.SharePointAdminOnline
		#Check if user is sharepoint administrator
		$isSharepointAdministrator = Test-IsUserSharepointAdministrator
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online Tenant Admin Info",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSTenantInfo');
		}
		Write-Information @msg
		if ($isSharepointAdministrator) {
			#body
			$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="334" ObjectPathId="333" /><Query Id="335" ObjectPathId="333"><Query SelectAllProperties="true"><Properties><Property Name="HideDefaultThemes" ScalarProperty="true" /></Properties></Query></Query></Actions><ObjectPaths><Constructor Id="333" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>'
			$params = @{
				Authentication = $sps_auth;
				Data = $body_data;
			}
			#call SPS
			$sps_tenant_admin_details = Invoke-MonkeySPSUrlRequest @params
		}
	}
	end {
		if ($sps_tenant_admin_details) {
			$sps_tenant_admin_details.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.TenantDetails')
			[pscustomobject]$obj = @{
				Data = $sps_tenant_admin_details;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_tenant_admin_details = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Tenant Admin details",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSTenantDetailsEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
