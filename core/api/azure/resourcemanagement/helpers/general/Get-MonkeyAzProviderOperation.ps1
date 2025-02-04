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

Function Get-MonkeyAzProviderOperation {
    <#
        .SYNOPSIS
		Get operations for specified provider

        .DESCRIPTION
		Get operations for specified provider

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzProviderOperation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="Resource provider")]
        [String]$Provider
    )
    try{
        $api = $O365Object.internal_config.resourceManager.Where({$_.name -eq 'ProviderOperations'}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        if($null -ne $api){
            $api_version = $api.api_version;
        }
        else{
            $api_version = '2022-04-01'
        }
        $base_uri = [String]::Empty
        $Server = ("{0}" -f $O365Object.Environment.ResourceManager.Replace('https://',''))
        $base_uri = ("{0}/{1}" -f $base_uri, '/providers/Microsoft.Authorization/providerOperations')
        if($PSBoundParameters.ContainsKey('Provider') -and $PSBoundParameters['Provider']){
            $base_uri = ("{0}/{1}" -f $base_uri, $PSBoundParameters['Provider'])
        }
        #Add api version
        $base_uri = ("{0}?api-version={1}" -f $base_uri, $api_version)
        #Add expand
        $base_uri = ('{0}&$expand={1}' -f $base_uri, 'resourceTypes')
        #Remove double slashes
        $base_uri = [regex]::Replace($base_uri,"/+","/")
        $final_uri = ("{0}{1}" -f $Server,$base_uri)
        $final_uri = [regex]::Replace($final_uri,"/+","/")
        $final_uri = ("https://{0}" -f $final_uri.ToString())
        #Param
        $p = @{
            Authentication = $O365Object.auth_tokens.ResourceManager;
            Environment = $O365Object.Environment;
            OwnQuery = $final_uri;
        }
        Get-MonkeyRMObject @p
    }
    catch{
        Write-Verbose $_
    }
}

