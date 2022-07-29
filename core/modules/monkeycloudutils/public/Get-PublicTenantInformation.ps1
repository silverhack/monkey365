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

Function Get-PublicTenantInformation{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PublicTenantInformation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Username', HelpMessage= "User to resolve")]
        [String]$Username,

        [parameter(Mandatory= $true, ParameterSetName = 'Domain', HelpMessage= "Domain to resolve")]
        [String]$Domain

    )
    $az_domain_metadata = $metadata = $null
    Switch($PSCmdlet.ParameterSetName){
        'Username'{
            Write-Information ("Resolving TenantId by using {0} username" -f $Username)
            $Uri_Username = ("https://login.microsoftonline.com/getuserrealm.srf?login={0}&json=1" -f $Username)
            $metadata = Invoke-RestMethod -Uri $Uri_Username -Method Get -ContentType 'application/json'
            if ($metadata.DomainName){
                $Uri_tmp_domain = ("https://login.windows.net/{0}/.well-known/openid-configuration" -f $metadata.DomainName)
                $domain_metadata = Invoke-RestMethod -Uri $Uri_tmp_domain -Method Get -ContentType 'application/json'
                if($domain_metadata){
                    [psobject]$az_domain_metadata = @{
                        domainName = $metadata.DomainName;
                        NameSpaceType = $metadata.NameSpaceType;
                        FederationBrandName = $metadata.FederationBrandName;
                        CloudInstanceName = $metadata.CloudInstanceName;
                        TenantID = $domain_metadata.token_endpoint.Split(‘/’)[3]
                    }
                }
            }
        }
        'Domain'{
            Write-Information ("Resolving TenantId by using {0} domain" -f $Domain)
            $Uri_Domain = ("https://login.windows.net/{0}/.well-known/openid-configuration" -f $Domain)
            try{
                $metadata = Invoke-RestMethod -Uri $Uri_Domain -Method Get -ContentType 'application/json' -ErrorVariable requestError
            }
            catch{
                if($_.ErrorDetails.Message){
                    Write-Debug $_.ErrorDetails.Message
                }
                else{
                    Write-Debug $_.Exception.Message
                    Write-Debug $_.Exception.Response.StatusDescription
                }
            }
            if($metadata){
                $empty = [system.guid]::Empty
                $fake_user = ("{0}@{1}" -f $empty, $Domain)
                $Uri_Fake_User = ("https://login.microsoftonline.com/getuserrealm.srf?login={0}&json=1" -f $fake_user)
                $fake_metadata = Invoke-RestMethod -Uri $Uri_Fake_User -Method Get -ContentType 'application/json'
                if($fake_metadata){
                    #Generate object
                    [psobject]$az_domain_metadata = @{
                        domainName = if($fake_metadata.psobject.properties.Item('DomainName')){$fake_metadata.DomainName}else{$null};
                        NameSpaceType = $fake_metadata.NameSpaceType;
                        FederationBrandName = if($fake_metadata.psobject.properties.Item('FederationBrandName')){$fake_metadata.FederationBrandName}else{$null};
                        CloudInstanceName = if($fake_metadata.psobject.properties.Item('CloudInstanceName')){$fake_metadata.CloudInstanceName}else{$null};
                        TenantRegionScope = if($metadata.psobject.properties.Item('tenant_region_scope')){$metadata.tenant_region_scope}else{$null};
                        TenantRegionSubScope = if($metadata.psobject.properties.Item('tenant_region_sub_scope')){$metadata.tenant_region_sub_scope}else{$null};
                        TenantID = $metadata.token_endpoint.Split(‘/’)[3]
                    }
                }
            }
        }
    }
    if($null -ne $az_domain_metadata){
        return $az_domain_metadata
    }
    else{
        Write-Information "Unable to get information"
    }
}

