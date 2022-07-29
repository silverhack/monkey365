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


Function Get-AssignedDomain{
    <#
        .SYNOPSIS
		Get Domains

        .DESCRIPTION
		Get Domains

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AssignedDomain
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    try{
        $uri = ("{0}/v1.0/domains" -f $O365Object.Environment.Graphv2)
        $params = @{
            Environment = $O365Object.Environment;
            Authentication = $O365Object.auth_tokens.MSGraph;
            RawQuery = $uri;
        }
        $domains = Get-GraphObject @params
        return $domains
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
    }
}
