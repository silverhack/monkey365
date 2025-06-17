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


Function Get-MonkeyGraphAADTenantDetail{
    <#
        .SYNOPSIS
		Get Tenant details

        .DESCRIPTION
		Get Tenant details

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADTenantDetail
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'TenantId', HelpMessage="Tenant")]
        [String]$TenantId
    )
    Begin{
        $Environment = $O365Object.Environment;
        $graphAd = $O365Object.auth_tokens.Graph;
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
        #set null
        $tenantDetails = $null
    }
    Process{
        try{
            if($PSCmdlet.ParameterSetName -eq 'TenantId'){
                $query = ('{0}/tenantDetails' -f $TenantId)
                $Server = [System.Uri]::new($Environment.Graph)
                $final_uri = [System.Uri]::new($Server,$query)
                $ownQuery = $final_uri.ToString()
                $p = @{
                    Authentication = $graphAd;
                    OwnQuery = $ownQuery;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $aadConf.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $tenantDetails = Get-MonkeyGraphObject @p
            }
            else{
                $query = ('/myOrganization/tenantDetails')
                $Server = [System.Uri]::new($Environment.Graph)
                $final_uri = [System.Uri]::new($Server,$query)
                $ownQuery = $final_uri.ToString()
                $p = @{
                    Authentication = $graphAd;
                    OwnQuery = $ownQuery;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $aadConf.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $tenantDetails = Get-MonkeyGraphObject @p
            }
            #return object
            $tenantDetails
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
        #nothing to do here
    }
}

