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


Function Get-DomainInfo{
    <#
        .SYNOPSIS
		Get DomainInfo

        .DESCRIPTION
		Get DomainInfo

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DomainInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="Domains to get info")]
        [Object]$Domains
    )
    try{
        $domainInfo = @()
        foreach ($domain in $Domains){
            $uri = ("{0}/v1.0/domains/{1}" -f $O365Object.Environment.Graphv2, $domain.id)
            $params = @{
                Environment = $O365Object.Environment;
                Authentication = $O365Object.auth_tokens.MSGraph;
                RawQuery = $uri;
            }
            $info = Get-GraphObject @params
            $domainInfo+=$info
        }
        return $domainInfo
    }
    catch{
        #Write message
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'Error';
            Tags = @('AADDomainError');
        }
        Write-Error @msg
        return $null
    }
}
