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

Function Get-DashboardTable{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DashboardTable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Report')]
        [Object]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage = 'Rules')]
        [Object]$Rules,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Get xml template
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Get rules
        If($PSBoundParameters.ContainsKey('Rules') -and $PSBoundParameters['Rules']){
            $allRules = $PSBoundParameters['Rules']
        }
        ElseIf($null -ne (Get-Variable -Name Rules -Scope Script -ErrorAction Ignore)){
            $allRules = $script:Rules
        }
        Else{
            $allRules = $null;
        }
        #Set table
        $table = [xml] '<table class="table monkey-table" id="dashboard_table" width="100%" type="Default"><thead><tr><th>Services</th><th>Rules</th><th>Findings</th></tr></thead><tbody></tbody><tfoot><tr><td class="text-center">data</td></tr></tfoot></table>'
    }
    Process{
        If($null -ne $allRules){
            $groupedFindings = $InputObject |Group-Object serviceType -ErrorAction Ignore
            $groupedFindings = $groupedFindings | Select-Object Name, @{Name='flagged';Expression={@($_.Group.Where({$_.level.ToLower() -ne "good" -and $_.level.ToLower() -ne "manual"})).Count}}
            #Add rules
            ForEach($finding in @($groupedFindings)){
                $RuleCount = @($allRules).Where({$_.serviceType -eq $finding.Name}).Count #@($rules | Where-Object {$_.serviceType -eq $flag.Name}).Count
                If($null -eq $finding.flagged){
                    $finding.flagged = 1;
                }
                $finding | Add-Member -Type NoteProperty -name rules -value $RuleCount -Force
            }
            #Get body and create td/tr
            $tbody = $table.SelectSingleNode("table/tbody")
            $tr = $table.CreateElement("tr")
            $td = $table.CreateElement("td")
            Foreach($finding in @($groupedFindings)){
                $arrayObjects = [System.Collections.Generic.List[System.Object]]::new()
                #Create Img object
                $imgProperties = @{
                    Name = 'img';
                    Attributes = @{
                        src = ($finding.Name | Get-SvgIcon);
                        alt = $finding.Name;
                    };
                    Template = $table;
                }
                $imgObj = New-HtmlTag @imgProperties
                #Add to array
                [void]$arrayObjects.Add($imgObj);
                #span element
                $spanProperties = @{
                    Name = 'span';
                    ClassName = 'monkey-table-resource';
                    Text = $finding.Name;
                    CreateTextNode = $true;
                    Template = $table;
                }
                #Create element
                $spanObj = New-HtmlTag @spanProperties
                #Add to array
                [void]$arrayObjects.Add($spanObj);
                #Create a link
                $aProperties = @{
                    Name = 'a';
                    Attributes = @{
                        href = ("javascript:show('{0}')" -f $finding.Name.ToLower().Replace(' ','-'));
                        class = "table-link";
                    };
                    AppendObject = $arrayObjects;
                    Template = $table;
                }
                $aObj = New-HtmlTag @aProperties
                #Add Service
                $service_td = $td.Clone()
                [void]$service_td.AppendChild($aObj)
                #Create resources
                #$resources_td = $td.Clone()
                #$resources_td.InnerText = $finding.resources;
                #Create rules
                $rules_td = $td.Clone()
                $rules_td.InnerText = $finding.rules;
                #Create findings
                $findings_td = $td.Clone()
                $findings_td.InnerText = $finding.flagged;
                #Add to tr
                If($service_td -and $rules_td -and $findings_td){
                    $my_tr = $tr.Clone()
                    [void]$my_tr.AppendChild($service_td)
                    #[void]$my_tr.AppendChild($resources_td)
                    [void]$my_tr.AppendChild($rules_td)
                    [void]$my_tr.AppendChild($findings_td)
                    #Add to tbody
                    [void]$tbody.AppendChild($my_tr)
                }
            }
            #Adjust footer
            $number_of_columns = $table.table.thead.tr.th.Count
            [void]$table.table.tfoot.tr.td.SetAttribute("colspan", $number_of_columns)
            $table.table.tfoot.tr.td.InnerText = "Monkey365 Dashboard"
            #Import table
            $newTable = $TemplateObject.ImportNode($table.DocumentElement,$true);
            #Create new Card
            $p = @{
                CardTitle = "Dashboard Table"
                Icon = "bi bi-table me-2";
                AppendObject = $newTable;
                Template = $TemplateObject;
            }
            New-HtmlContainerCard @p
        }
        Else{
            Write-Warning "Unable to compile dashboard table. Missing rules"
        }
    }
    End{
    }
}
