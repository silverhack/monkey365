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

Function Get-PSExoModuleFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoModuleFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Purview")]
        [Switch]$Purview,

        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication
    )
    Try{
        If($PSBoundParameters['Purview'] -and $PSBoundParameters['Purview'].IsPresent){
            #Get Security and Compliance Auth token
			If($PSBoundParameters.ContainsKey('Authentication') -and $PSBoundParameters['Authentication']){
                $ExoAuth = $PSBoundParameters['Authentication']
            }
            Else{
                $ExoAuth = $O365Object.auth_tokens.ComplianceCenter
            }
            #Get TenantId from token
            #$tid = Read-JWTtoken -token $O365Object.auth_tokens.ComplianceCenter.AccessToken | Select-Object -ExpandProperty tid -ErrorAction Ignore
			#Get Backend Uri
			$Uri = $O365Object.SecCompBackendUri
            #Add AnchorMailbox header
            If($O365Object.isConfidentialApp){
                If($null -ne $O365Object.Tenant.MyDomain){
                    $extraHeader = @{
                        'X-AnchorMailbox' = ("UPN:Monkey365@{0}" -f $O365Object.Tenant.MyDomain.id);
                    }
                }
                ElseIf((Test-IsValidTenantId -TenantId $O365Object.TenantId) -eq $false){
                    $extraHeader = @{
                        'X-AnchorMailbox' = ("UPN:Monkey365@{0}" -f $O365Object.TenantId);
                    }
                }
                Else{
                    Write-Warning "Tenant Name was not recognized. Unable to get Compliance Center backend url"
                    return
                }
                #Get Module file
                $param = @{
                    Authentication = $ExoAuth;
                    EndPoint = $Uri;
                    ObjectType = 'EXOModuleFile';
                    Headers = $extraHeader;
                    ExtraParameters = "Version=3.2.0";
                    Method = "GET";
                    TimeOut = 50;
                    RemoveOdataHeader = $true;
                    APIVersion = 'v1.0';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            Else{
                #Get Module file
                $param = @{
                    Authentication = $ExoAuth;
                    EndPoint = $Uri;
                    ObjectType = 'EXOModuleFile';
                    ExtraParameters = "Version=3.2.0";
                    Method = "GET";
                    TimeOut = 50;
                    RemoveOdataHeader = $true;
                    APIVersion = 'v1.0';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
        }
        Else{
            #Get environment
            $Environment = $O365Object.Environment
            #Get Auth token
            If($PSBoundParameters.ContainsKey('Authentication') -and $PSBoundParameters['Authentication']){
                $ExoAuth = $PSBoundParameters['Authentication']
            }
            Else{
                $ExoAuth = $O365Object.auth_tokens.ExchangeOnline
            }
            #Get Module file
            $param = @{
                Authentication = $exoAuth;
                Environment = $Environment;
                ObjectType = 'EXOModuleFile';
                ExtraParameters = "Version=3.5.0";
                Method = "GET";
                TimeOut = 50;
                RemoveOdataHeader = $true;
                APIVersion = 'v1.0';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
        }
        Get-PSExoAdminApiObject @param
    }
    Catch{
        Write-Verbose $_
    }
}

