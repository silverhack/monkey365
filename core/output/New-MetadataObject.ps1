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


Function New-MetadataObject{
    <#
        .SYNOPSIS
		Function to create new metadata object

        .DESCRIPTION
		Function to create new metadata object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MetadataObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider
    )
    try{
        switch ($Provider.ToLower()){
            { @("microsoft365", "entraid") -contains $_ }{
                $_object = [ordered]@{
                    projectId = [System.Guid]::NewGuid().Guid;
                    Instance = $O365Object.Instance;
                    tenantID = $O365Object.Tenant.TenantId;
                    tenantName = $O365Object.Tenant.TenantName;
                    subscriptionName = $null;
                    subscriptionId = $null;
                    raw_data = $null;
                    IncludeEntraID = $O365Object.IncludeEntraID;
                    jobFolder = $null;
                    date = (Get-Date).ToUniversalTime().ToString("yyyy/MM/dd HH:mm:ss");
                }
            }
            'azure'{
                $_object = [ordered]@{
                    projectId = [System.Guid]::NewGuid().Guid;
                    Instance = $O365Object.Instance;
                    tenantID = $O365Object.Tenant.TenantId;
                    tenantName = $O365Object.Tenant.TenantName;
                    subscriptionName = $O365Object.current_subscription.displayName;
                    subscriptionId = $O365Object.current_subscription.subscriptionId;
                    raw_data = $null;
                    IncludeEntraID = $O365Object.IncludeEntraID;
                    jobFolder = $null;
                    date = (Get-Date).ToUniversalTime().ToString("yyyy/MM/dd HH:mm:ss");
                }
            }
            Default{
                $_object = [ordered]@{
                    projectId = [System.Guid]::NewGuid().Guid;
                    Instance = $O365Object.Instance;
                    tenantID = $O365Object.Tenant.TenantId;
                    tenantName = $O365Object.Tenant.TenantName;
                    subscriptionName = $null;
                    subscriptionId = $null;
                    raw_data = $null;
                    IncludeEntraID = $O365Object.IncludeEntraID;
                    jobFolder = $null;
                    date = (Get-Date).ToUniversalTime().ToString("yyyy/MM/dd HH:mm:ss");
                }
            }
        }
        return $_object
    }
    catch{
        throw ("{0}. {1}" -f $message.UnableToCreateMonkeyObject,$_.Exception.Message)
    }
}

