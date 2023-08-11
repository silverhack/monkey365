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


function Get-MonkeyPowerBIBackendUri {
<#
        .SYNOPSIS
		Get PowerBI backend uri

        .DESCRIPTION
		Get PowerBI backend uri

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBIBackendUri
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param()
    Begin{
        $backendUri = $uri = $access_token = $null
        if($null -ne (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
            $Environment = $O365Object.Environment
            if($null -ne ($O365Object.auth_tokens.PowerBI)){
                $access_token = $O365Object.auth_tokens.PowerBI
                #Get Cluster URI
                $uri = ('{0}/{1}' -f $Environment.PowerBIAPI,'/spglobalservice/GetOrInsertClusterUrisByTenantlocation')
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
                ActivityId = (New-Guid).ToString()
                RequestId = (New-Guid).ToString()
                Authorization = $AuthHeader
            }
            $param = @{
                Url = $uri;
                Method = 'Put';
                Headers = $requestHeader;
                Accept = 'application/json';
                UserAgent = $O365Object.UserAgent;
                Verbose = $O365Object.Verbose;
                Debug = $O365Object.Debug;
                InformationAction = $O365Object.InformationAction;
            }
            $Object = Invoke-MonkeyWebRequest @param
            if($null -ne $Object -and $null -ne ($Object.PsObject.Properties.Item('DynamicClusterUri'))){
                try{
                    $backendUri = $Object | Select-Object -ExpandProperty DynamicClusterUri
                }
                catch{
                    $msg = @{
				        MessageData = ($message.PowerBIBackendError -f $O365Object.TenantID);
				        callStack = (Get-PSCallStack | Select-Object -First 1);
				        logLevel = 'warning';
				        InformationAction = $InformationAction;
				        Tags = @('PowerBIClusterUriError');
			        }
			        Write-Warning @msg
                    #Add verbose
                    $msg.MessageData = $_.Exception;
                    $msg.logLevel = 'verbose';
                    Write-Verbose @msg
                }
            }
        }
    }
    End{
        return $backendUri
    }
}