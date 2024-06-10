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

Function Get-MonkeyCSOMOffice365Tenant{
    <#
        .SYNOPSIS
        Get SharePoint Online tenant information

        .DESCRIPTION
        Get SharePoint Online tenant information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMOffice365Tenant
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param ()
    Begin{
        #Microsoft 365 Tenant
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="71" ObjectPathId="70" /><Query Id="72" ObjectPathId="70"><Query SelectAllProperties="true"><Properties /></Query></Query></Actions><ObjectPaths><Constructor Id="70" TypeId="{e45fd516-a408-4ca4-b6dc-268e2f1f0f83}" /></ObjectPaths></Request>'
    }
    Process{
        try{
            If($null -ne $O365Object.auth_tokens.SharePointAdminOnline){
                $p = @{
                    Authentication = $O365Object.auth_tokens.SharePointAdminOnline;
                    Data = $body_data;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                #Execute query
                $m365_tenant = Invoke-MonkeyCSOMRequest @p
                if($m365_tenant){
                    #Add url
                    $m365_tenant | Add-Member -type NoteProperty -name Url -value $O365Object.auth_tokens.SharePointAdminOnline.Resource -Force
                    return $m365_tenant
                }
            }
        }
        Catch{
            $msg = @{
                MessageData = $_.Exception.Message;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('CSOMM365TenantError');
            }
            Write-Error @msg
        }
    }
    End{
        #Nothing to do here
    }
}
