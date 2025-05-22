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

Function ConvertTo-ExoRestCommand{
    <#
        .SYNOPSIS
        Convert string to EXO admin API command

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-ExoRestCommand
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True)]
        [String]$Command
    )
    Begin{
        $output = @{
            CmdletInput = @{
                CmdletName = $null;
                Parameters = @{
                }
            }
        }
    }
    Process{
        $Command = $Command.Trim() -replace "\s+"," "
        $attr = $Command.Split(' ')
        for($i=1;$i -lt $attr.Length;$i++){
            if(-not [string]::IsNullOrEmpty($attr[$i])){
                if($attr[$i].StartsWith('-')){
                    $p = $attr[$i].Split('-')[1]
                    $output.CmdletInput.Parameters.Add($p,$attr[$i+1])
                    continue
                }
            }
        }
        #Add command
        $output.CmdletInput.CmdletName = $attr[0]
        return ($output | ConvertTo-Json)
    }
    End{
        #Nothing to do here
    }
}
