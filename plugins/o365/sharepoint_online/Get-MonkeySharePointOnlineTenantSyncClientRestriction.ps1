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


function Get-MonkeySharePointOnlineTenantSyncClientRestriction {
<#
        .SYNOPSIS
		Plugin to get information about SPS Tenant Sync Client Restriction

        .DESCRIPTION
		Plugin to get information about SPS Tenant Sync Client Restriction

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineTenantSyncClientRestriction
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
			Id = "sps0011";
			Provider = "Microsoft365";
			Title = "Plugin to get information about SPS Tenant Sync Client Restriction";
			Group = @("SharePointOnline");
			ServiceName = "SharePoint Online Tenant Sync Client Restriction";
			PluginName = "Get-MonkeySharePointOnlineTenantSyncClientRestriction";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Get Access Token from SPO
		$sps_auth = $O365Object.auth_tokens.SharePointAdminOnline
		#Check if user is sharepoint administrator
		$isSharepointAdministrator = Test-IsUserSharepointAdministrator
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Sharepoint Online Tenant Sync Client restriction",$O365Object.TenantID);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('SPSTenantSyncInfo');
		}
		Write-Information @msg
		if ($isSharepointAdministrator) {
			#body
			$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="4" ObjectPathId="3" /><Query Id="5" ObjectPathId="3"><Query SelectAllProperties="true"><Properties><Property Name="IsUnmanagedSyncClientForTenantRestricted" ScalarProperty="true" /><Property Name="AllowedDomainListForSyncClient" ScalarProperty="true" /><Property Name="BlockMacSync" ScalarProperty="true" /><Property Name="ExcludedFileExtensionsForSyncClient" ScalarProperty="false" /><Property Name="OptOutOfGrooveBlock" ScalarProperty="true" /><Property Name="OptOutOfGrooveSoftBlock" ScalarProperty="true" /><Property Name="DisableReportProblemDialog" ScalarProperty="true" /></Properties></Query></Query></Actions><ObjectPaths><Constructor Id="3" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>'
			$params = @{
				Authentication = $sps_auth;
				Data = $body_data;
			}
			#call SPS
			$sps_tenant_sync_info = Invoke-MonkeySPSUrlRequest @params
		}
	}
	end {
		if ($sps_tenant_sync_info) {
			$sps_tenant_sync_info.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Tenant.SyncClientRestriction')
			[pscustomobject]$obj = @{
				Data = $sps_tenant_sync_info;
				Metadata = $monkey_metadata;
			}
			$returnData.o365_spo_tenant_sync_restrictions = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online Tenant Sync Client Restriction",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('SPSTenantSyncEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
