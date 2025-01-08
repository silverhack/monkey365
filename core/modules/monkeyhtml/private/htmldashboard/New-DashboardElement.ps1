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

Function New-DashboardElement{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-DashboardElement
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$element
    )
    Process{
        if($null -ne $element.PSObject.Properties.Item('name')){
            switch ($element.name.ToLower()) {
                'table'
                {
                    $raw_section = Get-DashboardHtmlTable -table_data $element
                }
                'chart'
                {
                    $raw_section = Build-HtmlChart -dataChart $element
                }
                default
                {
                    Write-Verbose ($script:messages.unknownDashboardElement -f $element.name)
                    $raw_section = $null
                }
            }
            #return section
            return $raw_section
        }
        else{
            return $null
        }
    }
}

