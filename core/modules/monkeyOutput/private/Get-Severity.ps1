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

Function Get-Severity{
    <#
        .SYNOPSIS
        Get severity
        .DESCRIPTION
        Get severity
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Severity
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
	Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Level")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Level
    )
    Process{
        if($null -eq $Level -or ($Level -eq [System.String]::Empty)){
            [Ocsf.SeverityId]::Unknown.ToString();
        }
        Else{
            $fw = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($Level.Split(' ')[0].ToLower())
            $_level = $Level.Replace($Level.Split(' ')[0],$fw);
            if([Ocsf.SeverityId]::IsDefined([Ocsf.SeverityId],$_level)){
                ([Ocsf.SeverityId]$_level).ToString()
            }
            Else{
                [Ocsf.SeverityId]::Unknown.ToString();
            }
        }
    }
}