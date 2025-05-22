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

Function New-HtmlMainDashboard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlMainDashboard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Report')]
        [Object]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage= "Horizontal stacked")]
        [Switch]$HorizontalStackedBar,

        [Parameter(Mandatory = $false, HelpMessage= "Donut chart")]
        [Switch]$Donut,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Div properties
        $divProperties = @{
            Name = 'div';
            ClassName = 'row';
            Id = "monkey-main-dashboard";
            Template = $TemplateObject;
        }
        #Create element
        $divContent = New-HtmlTag @divProperties
        #New parameters for Finding by service chart
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-FindingByServiceChart")
        $newPsboundParams = [ordered]@{}
        $param = $MetaData.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($PSBoundParameters.ContainsKey($p)){
                $newPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        #New parameters for Finding by severity chart
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-FindingBySeverityChart")
        $severityPsboundParams = [ordered]@{}
        $param = $MetaData.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($PSBoundParameters.ContainsKey($p)){
                $severityPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
    }
    Process{
        $findingByServiceChart = New-FindingByServiceChart @newPsboundParams
        If($findingByServiceChart){
            #Div properties
            $divProperties = @{
                Name = 'div';
                ClassName = 'col-md-8 grid-margin';
                AppendObject = $findingByServiceChart;
                Template = $TemplateObject;
            }
            #Create element
            $colMd8Div = New-HtmlTag @divProperties
            If($colMd8Div){
                [void]$divContent.AppendChild($colMd8Div);
            }
        }
        #Get Finding by severity chart
        $findingBySeverityChart = New-FindingBySeverityChart @severityPsboundParams
        If($findingBySeverityChart){
            #Div properties
            $divProperties = @{
                Name = 'div';
                ClassName = 'col-md-4 grid-margin';
                AppendObject = $findingBySeverityChart;
                Template = $TemplateObject;
            }
            #Create element
            $colMd4Div = New-HtmlTag @divProperties
            If($colMd4Div){
                [void]$divContent.AppendChild($colMd4Div);
            }
        }
        #Get table
        If($null -ne (Get-Variable -Name Rules -Scope Script -ErrorAction Ignore)){
            $p = @{
                InputObject = $InputObject;
                Rules = $script:Rules;
                Template = $TemplateObject;
            }
            $dashboardTable = Get-DashboardTable @p
            If($dashboardTable){
                #Div properties
                $divProperties = @{
                    Name = 'div';
                    ClassName = 'col-md-12 grid-margin';
                    AppendObject = $dashboardTable;
                    Template = $TemplateObject;
                }
                #Create element
                $colMd12Div = New-HtmlTag @divProperties
                If($colMd12Div){
                    [void]$divContent.AppendChild($colMd12Div);
                }
            }
        }
        return $divContent
    }
}
