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

Function Test-IsValidUrl{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-IsValidUrl
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    [OutputType([System.Boolean])]
    Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $true, HelpMessage="InputObjec")]
        [String]$InputObject
    )
    Process{
        [System.Uri]$out = $null;
        [System.Uri]::TryCreate($InputObject,[System.UriKind]::Absolute,[ref]$out) -and ($out.Scheme -eq [System.Uri]::UriSchemeHttp -or $out.Scheme -eq [System.Uri]::UriSchemeHttps)
    }
}

