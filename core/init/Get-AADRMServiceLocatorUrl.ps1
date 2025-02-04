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

Function Get-AADRMServiceLocatorUrl{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AADRMServiceLocatorUrl
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    try{
        if($O365Object.auth_tokens.AADRM){
            $access_token = $O365Object.auth_tokens.AADRM
            #Set Authorization Header
            $AuthHeader = ("MSOID {0}" -f $access_token.AccessToken)
            $requestHeader = @{"Authorization" = $AuthHeader}
            $post_data = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><FindServiceLocationsForUser xmlns="http://microsoft.com/DRM/ServiceLocatorService"><ServiceNames><ServiceLocationRequest><Type>AdminV2Service</Type></ServiceLocationRequest></ServiceNames></FindServiceLocationsForUser></soap:Body></soap:Envelope>'
            $url = "https://discover.aadrm.com/_wmcs/oauth2/certification/ServiceLocator.asmx"
            $p = @{
                Url = $url;
                Method = "Post";
                Data = $post_data;
                ContentType = 'text/xml; charset=utf-8';
                Headers = $requestHeader;
                disableSSLVerification = $true;
            }
            [xml]$xml_response = Invoke-MonkeyWebRequest @p
            #Get service locator url
            if($null -ne $xml_response){
                $ns = @{ns="http://microsoft.com/DRM/ServiceLocatorService"}
                $response = Select-Xml -Xml $xml_response -XPath '//ns:ServiceLocationResponse' -Namespace $ns -ErrorAction Ignore
                if($null -ne $response -and $null -ne ($response.PsObject.Properties.Item('Node'))){
                    $service_locator = $response.Node.Url
                    return $service_locator
                }
            }
        }
        else{
            $msg = @{
                MessageData = $message.AADRMServiceLocatorError;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('AADRMServiceLocatorError');
            }
            Write-Warning @msg
        }
    }
    catch{
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'error';
            Tags = @('AADRMServiceLocatorError');
        }
        Write-Verbose @msg
    }
}


