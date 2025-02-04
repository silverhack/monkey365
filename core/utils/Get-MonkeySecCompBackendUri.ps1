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


function Get-MonkeySecCompBackendUri {
<#
        .SYNOPSIS
		Get Security & Compliance backend uri

        .DESCRIPTION
		Get Security & Compliance backend uri

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySecCompBackendUri
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param()
    Begin{
        $backendUri = $uri = $access_token = $null
        if($null -ne (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
            if($null -ne ($O365Object.auth_tokens.ComplianceCenter) -and $null -ne $O365Object.TenantId){
                $access_token = $O365Object.auth_tokens.ComplianceCenter
                #Get URI
                $uri = ('{0}/AdminApi/v1.0/{1}/EXOModuleFile?Version=3.2.0' -f $O365Object.Environment.ComplianceCenterAPI,$O365Object.auth_tokens.ComplianceCenter.TenantId)
            }
        }
    }
    Process{
        if($null -ne $uri -and $null -ne $access_token){
            #Get Authorization Header
            $methods = $access_token | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
            if($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
                $AuthHeader = $access_token.CreateAuthorizationHeader()
            }
            else{
                $AuthHeader = ("Bearer {0}" -f $access_token.AccessToken)
            }
            $requestHeader = @{
                'client-request-id' = (New-Guid).ToString();
                "Prefer" = 'odata.maxpagesize=1000;';
                Authorization = $AuthHeader;
            }
            #Add AnchorMailbox header
            if($O365Object.isConfidentialApp){
                if($null -ne $O365Object.Tenant.MyDomain){
                    [void]$requestHeader.Add('X-AnchorMailbox',("UPN:Monkey365@{0}" -f $O365Object.Tenant.MyDomain.id))
                }
                elseif((Test-IsValidTenantId -TenantId $O365Object.TenantId) -eq $false){
                    [void]$requestHeader.Add('X-AnchorMailbox',("UPN:Monkey365@{0}" -f $O365Object.TenantId))
                }
                else{
                    Write-Warning "Tenant Name was not recognized. Unable to get Compliance Center backend url"
                    return
                }
            }
            $param = @{
                Url = $uri;
                Method = 'Get';
                Headers = $requestHeader;
                Accept = 'application/json';
                UserAgent = $O365Object.UserAgent;
                AllowAutoRedirect = $false;
                RawResponse = $true;
                Verbose = $O365Object.Verbose;
                Debug = $O365Object.Debug;
                InformationAction = $O365Object.InformationAction;
            }
            $Response = Invoke-MonkeyWebRequest @param
            if($null -ne $Response){
                #get backend
                try{
                    if($null -ne $Response.Headers.Location){
                        $backendUri = ("https://{0}" -f $Response.Headers.Location.Host.Replace('admin','ps.compliance'))
                    }
                }
                catch{
                    $msg = @{
				        MessageData = ($message.SecCompBackendError -f $O365Object.TenantID);
				        callStack = (Get-PSCallStack | Select-Object -First 1);
				        logLevel = 'warning';
				        InformationAction = $O365Object.InformationAction;
				        Tags = @('SecurityComplianceUriError');
			        }
			        Write-Warning @msg
                    #Add verbose
                    $msg.MessageData = $_.Exception;
                    $msg.logLevel = 'verbose';
                    Write-Verbose @msg
                }
            }
            else{
                $msg = @{
				    MessageData = ($message.SecCompBackendError -f $O365Object.TenantID);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = 'warning';
				    InformationAction = $O365Object.InformationAction;
				    Tags = @('SecurityComplianceUriError');
			    }
			    Write-Warning @msg
            }
        }
    }
    End{
        return $backendUri
    }
}

