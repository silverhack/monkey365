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


Function Get-SubscribedSKu{
    <#
        .SYNOPSIS
		Get subscribedSKus

        .DESCRIPTION
		Get subscribedSKus

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SubscribedSKu
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="Tenant")]
        [String]$Tenant
    )
    try{
        if([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq [System.Guid]::Empty){
            $Tenant = "/myOrganization"
        }
        $uri = ("{0}/{1}/{2}?api-version={3}" -f $O365Object.Environment.Graph, $Tenant, "subscribedSkus", "1.6")
        $params = @{
            Environment = $O365Object.Environment;
            Authentication = $O365Object.auth_tokens.Graph;
            OwnQuery = $uri;
        }
        $SubscribedSKu = Get-MonkeyRMObject @params
        return $SubscribedSKu
    }
    catch{
        #Write message
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'Error';
            Tags = @('AADSKUError');
        }
        Write-Error @msg
    }
}
