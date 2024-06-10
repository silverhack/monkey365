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

Function Get-MonkeyCSOMTenantSyncClientRestriction{
    <#
        .SYNOPSIS
        Get SharePoint Online tenant client sync restriction

        .DESCRIPTION
        Get SharePoint Online tenant client sync restriction

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMTenantSyncClientRestriction
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param ()
    Process{
        try{
            If($O365Object.isSharePointAdministrator){
                #Get Admin Access Token from SPO
		        $sps_auth = $O365Object.auth_tokens.SharePointAdminOnline
                #Tenant client sync restriction
                [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="4" ObjectPathId="3" /><Query Id="5" ObjectPathId="3"><Query SelectAllProperties="true"><Properties><Property Name="IsUnmanagedSyncClientForTenantRestricted" ScalarProperty="true" /><Property Name="AllowedDomainListForSyncClient" ScalarProperty="true" /><Property Name="BlockMacSync" ScalarProperty="true" /><Property Name="ExcludedFileExtensionsForSyncClient" ScalarProperty="false" /><Property Name="OptOutOfGrooveBlock" ScalarProperty="true" /><Property Name="OptOutOfGrooveSoftBlock" ScalarProperty="true" /><Property Name="DisableReportProblemDialog" ScalarProperty="true" /></Properties></Query></Query></Actions><ObjectPaths><Constructor Id="3" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>'
                $p = @{
                    Authentication = $sps_auth;
                    Data = $body_data;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                #Execute query
                Invoke-MonkeyCSOMRequest @p
            }
        }
        Catch{
            $msg = @{
                MessageData = $_.Exception.Message;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('CSOMTenantClientRestrictionError');
            }
            Write-Error @msg
        }
    }
    End{
        #Nothing to do here
    }
}
