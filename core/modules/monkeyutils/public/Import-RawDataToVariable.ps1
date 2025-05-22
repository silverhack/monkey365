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

Function Import-RawDataToVariable{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-RawDataToVariable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
            [parameter(Mandatory=$true, HelpMessage="raw data")]
            [Object]$raw_data,

            [parameter(Mandatory=$true, HelpMessage="Variable name")]
            [String]$varname,

            [parameter(Mandatory=$false, HelpMessage="Default is script")]
            [String]$Scope = "Script"
    )
    if($null -eq (Get-Variable -Name $varname.ToString() -ErrorAction Ignore)){
        #Set script variable
        $params = @{
            Name = $varname;
            Value = $raw_data;
            Scope = $Scope.ToString();
        }
        Set-Variable @params
    }
    else{
        Write-Debug ("{0} variable already exists" -f $varname.ToString())
    }
}

