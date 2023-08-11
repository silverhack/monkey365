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

Function Get-HttpMethod{
    <#
        .SYNOPSIS
        Get Http method

        .DESCRIPTION
        Get Http method

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HttpMethod
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False, HelpMessage='Request method')]
        [ValidateSet("GET","POST","PUT","HEAD")]
        [String]$Method = "GET"
    )
    try{
        #Method
        Switch ($Method.ToLower()) {
            'get'
            {
                $_method = [System.Net.Http.HttpMethod]::Get
            }
            'head'
            {
                $_method = [System.Net.Http.HttpMethod]::Head
            }
            'post'
            {
                $_method = [System.Net.Http.HttpMethod]::Post
            }
            'put'
            {
                $_method = [System.Net.Http.HttpMethod]::Put
            }
            Default
            {
                $_method = [System.Net.Http.HttpMethod]::Get
            }
        }
        return $_method
    }
    catch{
        Write-Error $_
    }
}