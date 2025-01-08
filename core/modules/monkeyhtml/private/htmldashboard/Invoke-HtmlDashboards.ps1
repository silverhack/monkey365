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

function Invoke-HtmlDashboards{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-HtmlDashboards
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    Param()
    Begin{
        $all_dashboards = @()
        $dashboard_template = [xml] '<div class="row container-fluid d-none"></div>'
    }
    Process{
        if($null -ne (Get-Variable -Name dashboards -ErrorAction Ignore)){
            foreach($dashboard in $dashboards){
                $raw_dashboard = $dashboard_template.Clone()
                Write-Verbose ($script:messages.NewDashboardMessage -f $dashboard.Name)
                $dashboard_id = ("{0}_{1}" -f $dashboard.name.Replace(' ','_'), (Get-Random -Minimum 20 -Maximum 1000))
                [void]$raw_dashboard.div.SetAttribute('id',$dashboard_id)
                #Create a new ROW
                Write-Debug ($script:messages.addRowToDashboard)
                $div = $raw_dashboard.CreateElement("div")
                [void]$div.SetAttribute('class',"row")
                $id = ("dashboard_row_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
                [void]$div.SetAttribute('id',$id)
                #Add row to main dashboard
                #[void]$raw_dashboard.div.AppendChild($container_row)
                #Populate ROW
                #$div = $raw_dashboard.SelectSingleNode(('//div[contains(@id,{0})]' -f $id))
                foreach($section in $dashboard.sections){
                    if ($section -is [PSCustomObject]){
                        $raw_section = New-DashboardElement -element $section
                        if($null -ne $raw_section){
                            if($raw_section -is [System.Xml.XmlDocument]){
                                Write-Verbose ($script:messages.addElementToDashboard -f $section.name)
                                $new_col = $raw_dashboard.ImportNode($raw_section.get_DocumentElement(), $True)
                                #Add elements to DIV
                                [void]$div.AppendChild($new_col)
                                [void]$raw_dashboard.div.AppendChild($div)
                            }
                            elseif($raw_section -is [System.Xml.XmlElement]){
                                Write-Verbose ($script:messages.addElementToDashboard -f $section.name)
                                $new_col = $raw_dashboard.ImportNode($raw_section, $True)
                                [void]$div.AppendChild($new_col)
                                [void]$raw_dashboard.div.AppendChild($div)
                            }
                            else{
                                Write-Verbose ($script:messages.unknownElement -f $raw_section.getType())
                            }
                        }
                    }
                    elseif($section -is [System.Object]){
                        #Create a new row
                        $div = $raw_dashboard.CreateElement("div")
                        [void]$div.SetAttribute('class',"row")
                        $id = ("dashboard_row_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
                        [void]$div.SetAttribute('id',$id)
                        foreach($new_section in $section){
                            $raw_section = New-DashboardElement -element $new_section
                            if($null -ne $raw_section){
                                if($raw_section -is [System.Xml.XmlDocument]){
                                    Write-Verbose ($script:messages.addElementToDashboard -f $new_section.name)
                                    $new_col = $raw_dashboard.ImportNode($raw_section.get_DocumentElement(), $True)
                                    #Add elements to DIV
                                    [void]$div.AppendChild($new_col)
                                    [void]$raw_dashboard.div.AppendChild($div)
                                }
                                elseif($raw_section -is [System.Xml.XmlElement]){
                                    Write-Verbose ($script:messages.addElementToDashboard -f $new_section.name)
                                    $new_col = $raw_dashboard.ImportNode($raw_section, $True)
                                    [void]$div.AppendChild($new_col)
                                    [void]$raw_dashboard.div.AppendChild($div)
                                }
                                else{
                                    Write-Verbose ($script:messages.unknownElement -f $raw_section.getType())
                                }
                            }
                        }
                    }
                }
                #Check if data
                if($raw_dashboard.LastChild.HasChildNodes){
                    $new_dashboard = [pscustomobject]@{
                        name = $dashboard.name;
                        id = $dashboard_id;
                        icon = $dashboard.icon;
                        data = $raw_dashboard;
                    }
                    $all_dashboards+=$new_dashboard
                }
            }
        }
    }
    End{
        if($all_dashboards){
            return $all_dashboards
        }
    }
}

