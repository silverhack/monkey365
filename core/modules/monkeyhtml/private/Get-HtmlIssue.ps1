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

Function Get-HtmlIssue{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlIssue
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    Begin{
        $all_html_issues = @()
        $all_detailed_objects = @()
        $azure_issues = Convert-IssuesToHtmlCards
        ######Create new DIVS for issues and detailed issues#####
    }
    Process{
        foreach($unit_issue in $azure_issues){
            $id_issue = $unit_issue.Name.ToLower().Replace(' ','-')
            # Create Azure page DIV
            $div_attr = [ordered]@{
                class = 'monkey-card-data';
                id = $id_issue;
                #style = 'display:none';
            }
            $div_body = New-HtmlTag -tagname "div" -attributes $div_attr
            #Get all rationale issues
            $rationale_issues = $unit_issue | Select-Object -ExpandProperty issues -ErrorAction SilentlyContinue
            if($null -ne $rationale_issues){
                $div_attr = [ordered]@{
                    class = 'row-data';
                    id = ('{0}_accordion' -f $id_issue);
                }
                $params = @{
                    tagname = "div";
                    attributes = $div_attr;
                    appendObject = $rationale_issues;
                }
                $all_rationale_issues = New-HtmlTag @params
                if($div_body -and $all_rationale_issues){
                    [void]$div_body.AppendChild($all_rationale_issues)
                }
            }
            #Get modal objects
            $extended_objects = $unit_issue | Select-Object -ExpandProperty extended_objects -ErrorAction SilentlyContinue
            if($extended_objects){
                $all_detailed_objects+=$extended_objects;
            }
            #Get Detailed issues
            $detailed_issues = $unit_issue | Select-Object -ExpandProperty detailed_issues -ErrorAction SilentlyContinue
            if($null -ne $detailed_issues){
                $div_attr = [ordered]@{
                    class = 'row-data';
                    id = ('{0}-detailed-issues' -f $id_issue);
                }
                $params = @{
                    tagname = "div";
                    attributes = $div_attr;
                    appendObject = $detailed_issues;
                }
                $all_detailed_issues = New-HtmlTag @params
                if($div_body -and $all_detailed_issues){
                    [void]$div_body.AppendChild($all_detailed_issues)
                }
            }
            #Get new card
            $params = @{
                defaultCard = $True;
                card_class = 'monkey-card';
                title_header = $unit_issue.Name.ToLower();
                img = (Get-HtmlIcon -icon_name $unit_issue.Name);
                body = $div_body;
            }
            $issue_card =  Get-HtmlCard @params
            #Add card to DIVs
            if($null -ne $issue_card){
                #Add filter
                $search_filter = New-HtmlIssueFilter
                if($search_filter -is [System.Xml.XmlDocument]){
                    Write-Verbose ("Add new filter to {0}" -f $unit_issue.Name)
                    $search_filter = $issue_card.ImportNode($search_filter.get_DocumentElement(), $True)
                    $my_div_body = $issue_card.SelectSingleNode('//div[contains(@class,"card-body")]')
                    #Add to first
                    [void]$my_div_body.PrependChild($search_filter)
                }
                #Add issue card to COL
                $params = @{
                    tagname = "div";
                    classname = "col-md-12";
                    appendObject = $issue_card;
                }
                $main_col = New-HtmlTag @params
                #Add to root DIV
                if($main_col){
                    $div_attr = [ordered]@{
                        class = 'row d-none';
                        id = ("{0}_row" -f $id_issue);
                    }
                    $params = @{
                        tagname = "div";
                        attributes = $div_attr;
                        appendObject = $main_col;
                    }
                    $root_div = New-HtmlTag @params
                    if($root_div){
                        #Check if charts
                        $all_charts = Invoke-HTMLCharts -category $unit_issue.Name
                        if($null -ne $all_charts){
                            Write-Verbose ($script:messages.insertChartsIntoElement -f $unit_issue.Name)
                            #Add to first
                            [void]$root_div.PrependChild($template.ImportNode($all_charts.get_DocumentElement(), $True))
                        }
                        #Add to array
                        $all_html_issues+=$root_div
                    }
                    else{
                        Write-Verbose ($script:messages.unableTocreateElement -f $unit_issue.Name)
                    }
                }
            }
            else{
                Write-Verbose ($script:messages.unableTocreateCardElement -f $unit_issue.Name)
            }
        }
    }
    End{
        $formatted_issues = [ordered]@{
            html_issues = $all_html_issues;
            extended_objects = $all_detailed_objects;
        }
        return $formatted_issues
    }
}
