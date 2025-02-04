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


Function Get-MonkeyAzTenant{
    <#
        .SYNOPSIS
		Get Tenant details from Azure

        .DESCRIPTION
		Get Tenant details from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzTenant
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Tenant")]
        [String]$TenantId
    )
    Begin{
        $Environment = $O365Object.Environment;
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'tenant'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
        #set null
        $tenantDetails = $null
    }
    Process{
        try{
            $query = ('/tenants?api-version={0}&$includeAllTenantCategories=true' -f $apiDetails.api_version)
            $Server = [System.Uri]::new($Environment.ResourceManager)
            $final_uri = [System.Uri]::new($Server,$query)
            $ownQuery = $final_uri.ToString()
            $p = @{
                Authentication = $rmAuth;
                OwnQuery = $ownQuery;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $tenantDetails = Get-MonkeyRMObject @p
        }
        catch{
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                Tags = @('AADTenantError');
            }
            Write-Verbose @msg
        }
    }
    End{
        if($null -ne $tenantDetails -and $TenantId){
            $tenantDetails | Where-Object {$_.tenantId -eq $TenantId} -ErrorAction Ignore
        }
        else{
            $tenantDetails
        }
    }
}


