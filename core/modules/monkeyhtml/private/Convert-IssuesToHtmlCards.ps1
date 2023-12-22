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

Function Convert-IssuesToHtmlCards{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-IssuesToHtmlCards
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [CmdletBinding()]
    Param()
    $all_ps_elements = @()
    #Get flagged issues
    $flagged_issues = $matched | Group-Object serviceType
    foreach($resource in $flagged_issues){
        #Create new ObjectElement PsObject that will hold all the properties that will make the HTML pages
        $ObjectElement = New-Object -TypeName PSCustomObject
        $ObjectElement | Add-Member -type NoteProperty -name name -value $resource.Name
        $all_html_issues = @()
        $all_detailed_issues = @()
        $all_modal_objects = @()
        #Iterate over all issues within group
        foreach($issue in $resource.Group){
            $issue | Add-Member -Type NoteProperty -name idSuffix1 -value ($issue.getNewIdSuffix()) -Force
            $issue | Add-Member -Type NoteProperty -name idSuffix2 -value ($issue.getNewIdSuffix()) -Force
            $new_html_issue = New-IssueCard -issue $issue -dashboard_name $resource.Name
            if($new_html_issue){
                $all_html_issues+=$new_html_issue
            }
        }
        #Add all converted html issues to ObjectElement psObject
        $ObjectElement | Add-Member -type NoteProperty -name issues -value $all_html_issues
        #Get detailed issues
        foreach($issue in $resource.Group){
            $table = $null;
            if($issue.level -ne 'Good'){
                $data = $issue | New-PsHtmlObject
                if($data){
                    if($data.table -eq 'asList'){
                        $params = @{
                            issue = $data.data;
                            emphasis = $data.emphasis;
                        }
                        $table = Get-HtmlTableAsListFromObject @params
                    }
                    else{
                        $table = Get-HtmlTableFromObject -issue $data
                    }
                }
                if($table){
                    $level = Get-IssueLevelSpanClass -level $issue.level
                    $params = @{
                        issueCard= $true;
                        card_class = 'monkey-issue-card d-none';
                        card_header_class = 'card-header-blue';
                        title_header = $issue.displayName;
                        span_class = $level;
                        id_card = $issue.idSuffix2;
                        body = $table;
                    }
                    $new_html_issue = Get-HtmlCard @params
                    #Add to array
                    $all_detailed_issues+=$new_html_issue
                    #Add here modal objects
                    if($null -ne $data.psobject.Properties.Item('extended_data')){
                        $extended_data = $data.extended_data;
                        foreach($modal_object in $extended_data){
                            $params = @{
                                raw_data= $modal_object.raw_data;
                                format = $modal_object.format;
                                id = $modal_object.id;
                            }
                            $new_modal_object = New-HtmlRawObjectModal @params
                            if($new_modal_object){
                                $all_modal_objects += $new_modal_object;
                            }
                        }
                    }
                }
            }
        }
        #Add detailed issues
        $ObjectElement | Add-Member -type NoteProperty -name detailed_issues -value $all_detailed_issues
        $ObjectElement | Add-Member -type NoteProperty -name extended_objects -value $all_modal_objects
        #Add issues
        $all_ps_elements+=$ObjectElement
    }
    #return data
    return $all_ps_elements
}
