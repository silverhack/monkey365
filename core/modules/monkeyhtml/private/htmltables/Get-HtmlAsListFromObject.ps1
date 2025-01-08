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

Function Get-HtmlTableAsListFromObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlTableAsListFromObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [Object]$issue,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$table_class = 'table-borderless',

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String[]]$emphasis,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$table_id,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$emphasis_class = 'cell-highlight'
        )
    Begin{
        <#
        #test add button
        foreach($element in $issue){
            $element | Add-Member -Type NoteProperty -name "External Link" -value "" -Force
        }
        #>
        $table = $issue | Microsoft.PowerShell.Utility\ConvertTo-Html -As List -Fragment
        $table = $table -replace "<td><hr></td>", "<td><hr/></td><td><hr/></td>"
        $table = "<table class="" id="" style='width:100%'><thead>`n{0}`n</thead>`n<tbody>`n{1}`n</tbody></table>" -f $table[1], ($table[2..($table.Count - 2)] -join "`n")
    }
    Process{
        [xml]$xmlTable = [System.Net.WebUtility]::HtmlDecode($table)
        #Process Table ID
        if(!$table_id){
            $table_id = [System.Guid]::NewGuid().Guid.Replace('-','').ToString()
            $xmlTable.table.SetAttribute('id',$table_id)
        }
        else{
            $xmlTable.table.SetAttribute('id',$table_id)
        }
        #Set table class
        $xmlTable.table.SetAttribute('class',$table_class)
        #Set Table mode
        $xmlTable.table.SetAttribute('type',"asList")
        #Set emphasis class
        if($emphasis){
            foreach($e in $emphasis){
                $element = $xmlTable.SelectNodes(('table/tbody/tr[td="{0}:"]' -f $e))
                if($element){
                    foreach($node in $element){
                        $node.LastChild.SetAttribute('class',$emphasis_class)
                    }
                }
            }
        }
    }
    End{
        return $xmlTable
    }
}

