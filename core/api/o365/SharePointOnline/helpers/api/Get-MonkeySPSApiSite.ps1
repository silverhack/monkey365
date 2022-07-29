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

Function Get-MonkeySPSApiSite{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSApiSite
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Auth Object")]
        [Object]$Authentication
    )
    Begin{
        $all_sites = @()
        $param = @{
            Authentication = $Authentication;
            endpoint = $Authentication.Resource;
            QueryText = '(contentclass:STS_Site)'
        }
        $raw_sites = Get-MonkeySPSApiSearch @param
    }
    Process{
        if($null -ne $raw_sites){
            foreach($rows in $raw_sites.PrimaryQueryResult.RelevantResults.Table.Rows){
                foreach($row in $rows){
                    #Parse element
                    $new_dict = @{}
                    foreach($element in $row.Cells){
                        try{
                            $valueType = $element.ValueType.Split('.')[1]
                        }
                        catch{
                            $valueType = "null"
                        }
                        if($null -eq $element.Value){
                            $new_dict.Add($element.Key,$null)
                        }
                        else{
                            $value = [System.Management.Automation.LanguagePrimitives]::ConvertTo($element.Value, $valueType)
                            $new_dict.Add($element.Key,$value)
                        }
                    }
                    $sps_object = New-Object PSObject -Property $new_dict
                    $all_sites+=$sps_object
                }
            }
        }
    }
    End{
        return $all_sites
    }
}
