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


Function Convert-SharePointOnlineDateString{
    <#
        .SYNOPSIS
		Converts string into datetime

        .DESCRIPTION
		Converts string into datetime

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-SharePointOnlineDateString
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="DateTime")]
        [String]$Date
    )
    Begin{
        $datetime = [ordered]@{
            Year = 0;
            Month = 0;
            Day = 0;
            Hour = 0;
            Minute = 0;
            Second = 0;
            MilliSecond = 0;
        }
        $keys = New-Object System.Collections.Generic.List[String]
        foreach($el in $datetime.Keys.GetEnumerator()){
            [void]$keys.Add($el.ToString())
        }
    }
    Process{
        try{
            if(![String]::IsNullOrEmpty($Date)){
                $new_arr = ($Date.Split('()')[1]).Split(',')
                for($i=0;$i -lt $new_arr.Count;$i++){
                    $datetime[$keys[$i]] = $new_arr[$i]
                }
            }
        }
        catch{
            Write-Warning $_
        }
    }
    End{
        try{
            [System.DateTime]::new(
                $datetime.Year,
                $datetime.Month,
                $datetime.Day,
                $datetime.Hour,
                $datetime.Minute,
                $datetime.Second,
                $datetime.MilliSecond
            )
        }
        catch{
            $Date
        }
    }
}
