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

Function Get-HashFromString{
    <#
        .SYNOPSIS
        Get Hash from String

        .DESCRIPTION
        Get Hash from String

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HashFromString
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory= $true, ValueFromPipeline = $True, HelpMessage= "Text")]
        [System.String]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="SHA256")]
        [Switch]$SHA256,

        [Parameter(Mandatory=$false, HelpMessage="SHA512")]
        [Switch]$SHA512
    )
    Begin{
        #Create dictionary with cryptograpy items
        $crypto = @{
            sha256 = [System.Security.Cryptography.SHA256]::Create();
            sha512 = [System.Security.Cryptography.SHA512]::Create();
        }
        # Ensure that SHA256 is used if integrity mechanism is not provided
        $method = $PSBoundParameters.Keys.Where({$_ -like '*SHA*'})
        If($method.Count -eq 0){
            $method = "sha256"
        }
        $cryptography = $crypto.Item($method.ToLower());
        #Check if cryptography is null
        If($null -eq $cryptography){
            Write-Warning "Unable to determine integrity check method. Using default SHA256 method"
            $cryptography = $crypto.Item('sha256');
        }
    }
    Process{
        [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject);
        [byte[]]$checksum = $cryptography.ComputeHash($bytes);
        return [System.BitConverter]::ToString($checksum).Replace('-', [String]::Empty).ToLowerInvariant()
    }
}