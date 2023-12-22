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

Function Get-HtmlTableFromObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlTableFromObject
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
            [String]$table_class = "monkey-table table-striped responsive",

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$table_id
        )
    Begin{
        try{
            #table class monkey-table nowrap table-striped responsive
            $data = $extended_data = $null
            $tmp_table = '<table class="" id="" style="width:100%;">${data}</table>'
            if($null -ne $issue.psobject.Properties.Item('data')){
                $data = $issue.data
            }
            if($null -ne $issue.psobject.Properties.Item('extended_data')){
                $extended_data = $issue.extended_data
            }
            $table = $data | Microsoft.PowerShell.Utility\ConvertTo-Html -As Table -Fragment
            $table = "<thead>`n{0}`n</thead>`n<tbody>`n{1}`n</tbody>" -f $table[2], ($table[3..($table.Count - 2)] -join "`n")
            $table = $tmp_table -replace '\${Data}', $table
            [xml]$xmlTable = [System.Net.WebUtility]::HtmlDecode($table)
            $i_attr = [ordered]@{
                class = 'bi bi-eye';
            }
            $i_element = @{
                tagname = "i";
                attributes = $i_attr;
                own_template = $xmlTable;
            }
            $btn_attr = [ordered]@{
                class = 'btn btn-primary';
                type = 'button';
            }
            $btn_element = @{
                tagname = "button";
                attributes = $btn_attr;
                own_template = $xmlTable;
            }
            #Get Format from issue
            if($null -ne $issue.psobject.Properties.Item('format')){
                $format = $issue.format;
            }
            else{
                $format = $null
            }
        }
        catch{
            Write-Verbose $_
            $xmlTable = $null;
        }
    }
    Process{
        if($null -ne $xmlTable){
            try{
                #Process Table ID
                if(!$table_id){
                    $table_id = [System.Guid]::NewGuid().Guid.Replace('-','').ToString()
                    $xmlTable.table.SetAttribute('id',$table_id)
                }
                else{
                    $xmlTable.table.SetAttribute('id',$table_id)
                }
                #Set Table mode
                $xmlTable.table.SetAttribute('type',"Normal")
                #Set table class
                $xmlTable.table.SetAttribute('class',$table_class)
                #Check for disable elements
                $tds = $xmlTable.SelectNodes("//td")
                foreach($td in $tds){
                    if($td.InnerText.ToLower() -eq 'disabled'){
                        $span_attr = [ordered]@{
                            class = 'badge bg-danger larger-badge';
                        }
                        $params = @{
                            tagname = "span";
                            attributes = $span_attr;
                            InnerText = $td.InnerText;
                            own_template = $xmlTable;
                        }
                        $span = New-HtmlTag @params
                        if($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }

                    }
                    elseif($td.InnerText.ToLower() -eq 'enabled'){
                        $span_attr = [ordered]@{
                            class = 'badge bg-success larger-badge';
                        }
                        $params = @{
                            tagname = "span";
                            attributes = $span_attr;
                            InnerText = $td.InnerText;
                            own_template = $xmlTable;
                        }
                        $span = New-HtmlTag @params
                        if($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }

                    }
                    elseif($td.InnerText.ToLower() -eq 'notset'){
                        $span_attr = [ordered]@{
                            class = 'badge bg-warning larger-badge';
                        }
                        $params = @{
                            tagname = "span";
                            attributes = $span_attr;
                            InnerText = $td.InnerText;
                            own_template = $xmlTable;
                        }
                        $span = New-HtmlTag @params
                        if($span){
                            $td.InnerText = $null
                            [void]$td.AppendChild($span)
                        }

                    }
                }
                #Check if html should be modified
                if($null -ne $format){
                    $format_elements = $null
                    if($null -ne $issue.format.psobject.Properties.Item('elements')){
                        $format_elements = $issue.format.elements
                    }
                    if($null -ne $format_elements){
                        foreach($e in $format_elements){
                            #also valid xpath
                            #$element = $xmlTable.SelectNodes(("//table//td[count(//table//th[text()='{0}']/preceding-sibling::*) +1]" -f $e.Name))
                            $element = $xmlTable.SelectNodes(('//td[(count(//tr/th[.="{0}"]/preceding-sibling::*)+1)]' -f $e.ItemName))
                            if($element){
                                foreach($node in $element){
                                    if($node.InnerText.ToString().ToLower() -eq $e.ItemValue.ToString()){
                                        $node.LastChild.SetAttribute('class',$e.className)
                                    }
                                }
                            }
                        }
                    }
                }
                #Check if action should be added to the table
                if($null -ne $issue.psobject.Properties.Item('actions')){
                    $actions = $issue.actions;
                    if(($null -ne $actions.psobject.Properties.Item('showGoToButton') -and $actions.showGoToButton -eq $True) -or ($null -ne $actions.psobject.Properties.Item('showModalButton') -and $actions.showModalButton -eq $True)){
                        #Set actions column
                        $thead = $xmlTable.SelectSingleNode("table/thead/tr")
                        #Add Actions column
                        $th = $xmlTable.CreateElement("th")
                        $th.InnerText = "actions"
                        [void]$thead.AppendChild($th)
                        #Iterate over body to add buttons
                        $tbody = $xmlTable.SelectSingleNode("table/tbody")
                        for ($idx=0;$idx -lt $tbody.ChildNodes.Count; $idx++){
                            $td = $xmlTable.CreateElement("td")
                            try{
                                #$format = $extended_data.Item($idx).format
                                if($idx -lt $extended_data.Count){
                                    $id = ("#{0}" -f $extended_data.Item($idx).id);
                                }
                                else{
                                    $id = $null;
                                }
                            }
                            catch{
                                $id = $null
                            }
                            if($null -ne $id -and $null -ne $actions.psobject.Properties.Item('showModalButton') -and $actions.showModalButton -eq $True){
                                $new_i_attrs = $i_element.Clone()
                                $new_i_attrs.attributes.class = 'bi bi-eye'
                                $i_tag = New-HtmlTag @new_i_attrs
                                $new_btn_attrs = $btn_element.Clone()
                                $new_btn_attrs.attributes.class = 'btn btn-primary me-2'
                                if($id){
                                    $new_btn_attrs.attributes."data-bs-target" = $id
                                    $new_btn_attrs.attributes."data-bs-toggle" = "modal"
                                }
                                $btn = New-HtmlTag @new_btn_attrs
                                if($btn){
                                    [void]$btn.AppendChild($i_tag)
                                    [void]$td.AppendChild($btn);
                                }
                            }
                            #Check if GoTo button should be added
                            if($null -ne $actions.psobject.Properties.Item('showGoToButton') -and $actions.showGoToButton -eq $True){
                                $new_link = New-GoToLink -issue $issue -idx $idx -actions $actions -instance $instance
                                if($null -ne $new_link){
                                    if($new_link -is [System.Xml.XmlDocument]){
                                        [void]$td.AppendChild($xmlTable.ImportNode($new_link.get_DocumentElement(), $True));
                                    }
                                    else{
                                        [void]$td.AppendChild($xmlTable.ImportNode($new_link, $True));
                                    }
                                }
                            }
                            [void]$tbody.ChildNodes.Item($idx).LastChild.AppendChild($td)
                            #Close i tags
                            $i_tags = $tbody.ChildNodes.Item($idx).SelectNodes("//i")
                            $i_tags | ForEach-Object {$_.InnerText = [string]::Empty}
                        }
                    }
                }
            }
            catch{
                Write-Warning ($script:messages.unableToCreateTable)
                Write-Debug $_.Exception
            }
        }
    }
    End{
        if($xmlTable){
            return $xmlTable
        }
    }
}
