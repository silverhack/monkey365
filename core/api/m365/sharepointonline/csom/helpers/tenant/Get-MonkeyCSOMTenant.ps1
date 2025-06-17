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

Function Get-MonkeyCSOMTenant{
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
            File Name	: Get-MonkeyCSOMTenant
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param ()
    Begin{
        #Tenant
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="334" ObjectPathId="333" /><Query Id="335" ObjectPathId="333"><Query SelectAllProperties="true"><Properties><Property Name="HideDefaultThemes" ScalarProperty="true" /></Properties></Query></Query></Actions><ObjectPaths><Constructor Id="333" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>'
    }
    Process{
        if($null -ne $O365Object.auth_tokens.SharePointAdminOnline){
            $p = @{
                Authentication = $O365Object.auth_tokens.SharePointAdminOnline;
                Data = $body_data;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Execute query
            Invoke-MonkeyCSOMRequest @p
        }
    }
    End{
        #Nothing to do here
    }
}

