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

Function Get-MonkeyExoRedirectUri{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyExoRedirectUri
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param
    (
        # Well Known Azure service
        [Parameter(Mandatory = $false, HelpMessage = 'Well Known Azure Service')]
        [ValidateSet("AzurePublic","AzureGermany","AzureChina","AzureUSGovernment")]
        [String]$Environment= "AzurePublic"
    )
    [psobject]$EnvRedirectUri = @{
        AzurePublic = 'https://login.microsoftonline.com/common/oauth2/nativeclient';
        AzureGermany = 'https://login.microsoftonline.de/organizations/oauth2/nativeclient';
        AzureChina = 'https://login.chinacloudapi.cn/organizations/oauth2/nativeclient';
        AzureUSGovernment = 'https://login.microsoftonline.us/organizations/oauth2/nativeclient';
    }
    #Check if resource exists
    if($EnvRedirectUri.ContainsKey($Environment)){
        return $EnvRedirectUri.Item($Environment)
    }
    else{
        Write-Verbose -Message ($Script:messages.UnknownEnvironment -f $Environment)
    }
}


