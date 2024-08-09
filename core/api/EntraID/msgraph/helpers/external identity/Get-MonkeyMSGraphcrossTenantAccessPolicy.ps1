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

Function Get-MonkeyMSGraphcrossTenantAccessPolicy {
    <#
        .SYNOPSIS
		Get cross-tenant access policy from Microsoft Graph

        .DESCRIPTION
		Get cross-tenant access policy from Microsoft Graph

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphcrossTenantAccessPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
	[CmdletBinding(DefaultParameterSetName = 'Basic')]
	Param (
        [parameter(Mandatory=$false, ParameterSetName = 'Default', HelpMessage="API version")]
        [Switch]$Default,

        [parameter(Mandatory=$false, ParameterSetName = 'Partner', HelpMessage="API version")]
        [Switch]$Partner,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        try{
            if($PSCmdlet.ParameterSetName -eq 'Partner'){
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies/crossTenantAccessPolicy/partners';
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = "beta";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $partners = Get-MonkeyMSGraphObject @p
                if($null -ne $partners){
                    foreach($partner in @($partners)){
                        $p = @{
                            TenantId = $partner.TenantId;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $tenantInfo = Find-MonkeyMSGraphTenantInformationByTenantId @p
                        if($null -ne $tenantInfo){
                            $partner | Add-Member -type NoteProperty -name federationBrandName -value $tenantInfo.federationBrandName -Force
                            $partner | Add-Member -type NoteProperty -name displayName -value $tenantInfo.displayName -Force
                            $partner | Add-Member -type NoteProperty -name defaultDomainName -value $tenantInfo.defaultDomainName -Force
                        }
                        Start-Sleep -Milliseconds 200
                    }
                    #return partners
                    return $partners
                }
            }
            ElseIf($PSCmdlet.ParameterSetName -eq 'Default'){
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies/crossTenantAccessPolicy/default';
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = "beta";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphObject @p
            }
            Else{
                $p = @{
                    Authentication = $graphAuth;
                    ObjectType = 'policies/crossTenantAccessPolicy';
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = "beta";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                Get-MonkeyMSGraphObject @p
            }
        }
        catch{
            Write-Error $_
        }
    }
    End{
        #Nothing to do here
    }
}