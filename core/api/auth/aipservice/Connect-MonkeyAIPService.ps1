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

Function Connect-MonkeyAIPService{
    <#
        .SYNOPSIS
        Function to connect to Azure Information Protection

        .DESCRIPTION
        Function to connect to Azure Information Protection

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyAIPService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Process{
        Try{
            If($null -eq $O365Object.auth_tokens.AADRM){
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Azure Information Protection")
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AIPTokenRequestInfoMessage');
                }
                Write-Information @msg
                #Set RedirectUri
                If($O365Object.cloudEnvironment -eq [Microsoft.Identity.Client.AzureCloudInstance]::AzureUsGovernment){
                    $redirectUri = "https://aadrm.us/adminpowershell"
                }
                Else{
                    $redirectUri = "https://aadrm.com/adminpowershell"
                }
                #Connect to Azure Information Protection
                $p = @{
                    Resource = $O365Object.Environment.AADRM;
                    AzureService = "AzurePowershell";
                    RedirectUri = $redirectUri;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $O365Object.auth_tokens.AADRM = Connect-MonkeyGenericApplication @p
                If($null -ne $O365Object.auth_tokens.AADRM){
                    #Get Service locator url
                    $service_locator = Get-AADRMServiceLocatorUrl
                    If($null -ne $service_locator){
                        #set internal object
                        If($O365Object.Environment.ContainsKey('aadrm_service_locator')){
                            $O365Object.Environment.aadrm_service_locator = $service_locator;
                        }
                        Else{
                            $O365Object.Environment.Add('aadrm_service_locator',$service_locator)
                        }
                        $O365Object.onlineServices.Item($service) = $true
                    }
                }
            }
        }
        Catch{
            $msg = @{
                Message = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                Tags = @('AIPAuthenticationError');
            }
            Write-Error @msg
        }
    }
}