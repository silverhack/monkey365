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

Function Get-MonkeyAzKeyVaultKeyRotationPolicy {
    <#
        .SYNOPSIS
		Get Azure keyvault key rotation policy

        .DESCRIPTION
		Get Azure keyvault key rotation policy

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKeyVaultKeyRotationPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'KeyVault key')]
        [Object]$key
    )
    try{
        $Auth = $O365Object.auth_tokens.AzureVault
        $kid = $key | Select-Object -ExpandProperty kid -ErrorAction Ignore
        If($null -ne $kid -and $null -ne $Auth){
            [URI]$URI = ("{0}/rotationpolicy?api-version={1}" -f $kid,'7.4')
            $p = @{
				Authentication = $Auth;
				OwnQuery = $URI;
				Environment = $O365Object.Environment;
				ContentType = 'application/json';
				Method = "GET";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
			}
			Get-MonkeyRMObject @p
        }
    }
    catch{
        Write-Verbose $_
    }
}

