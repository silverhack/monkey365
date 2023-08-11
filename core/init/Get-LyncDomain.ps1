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

Function Get-LyncDomain{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-LyncDomain
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    Begin{
        $lyncDiscoverUrl = $null;
        if($Script:Tenant){
            $defaultDomain = $Script:Tenant.verifiedDomains | Where-Object {$_.type -eq "Federated"}
            if($null -ne $defaultDomain -and $defaultDomain -is [pscustomobject]){
                $lyncDiscoverUrl = ("http://lyncdiscover.{0}" -f $defaultDomain[0].name)
            }
            else{
                $msg = @{
                    MessageData = ($message.LyncFederatedDomainNotFound -f $Script:Tenant.displayName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    Tags = @('AADRMServiceLocatorError');
                }
                Write-Warning @msg
            }
        }
        if($null -ne $lyncDiscoverUrl){
            $uri = ("{0}?Domain={1}" -f $lyncDiscoverUrl, $defaultDomain[0].name)
            $p = @{
                Url = $uri;
                Method = "Get";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $domain_metadata = Invoke-MonkeyWebRequest @p
        }
        else{
            $msg = @{
                MessageData = $message.LyncDomainNotResolved;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('AADRMServiceLocatorError');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($domain_metadata){
            [pscustomobject]$domain = $domain_metadata
            $p = @{
                Url = $domain._links.redirect.href;
                Method = "Get";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $root = Invoke-MonkeyWebRequest @p
            if($root){
                $originalUrl = New-Object System.Uri $root._links.self.href
                $newURI = ("https://{0}{1}/domain{2}" -f $originalUrl.Host, $originalUrl.AbsolutePath, $originalUrl.Query)
                $p = @{
                    Url = $newURI;
                    Method = "Get";
                    Encoding = 'application/vnd.microsoft.rtc.autodiscover+xml;v=1';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $last_step = Invoke-MonkeyWebRequest @p
                $xml_data = [xml]$last_step
            }
        }
    }
    End{
        if($xml_data){
            $domain = ($xml_data.AutodiscoverResponse.Domain.Link | Where-Object {$_.token -eq "External/RemotePowerShell"}).href
            $originalUrl = New-Object System.Uri $domain
            $newURI = ("https://{0}/OcsPowershellOAuth" -f $originalUrl.Host)
            return $newURI
        }
    }
}
