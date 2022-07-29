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

Function New-IssueCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-IssueCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$issue,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$dashboard_name
    )
    Begin{
        #Get issue level
        $level = Get-IssueLevelSpanClass -level $issue.level
        #Detailed issue skeleton
        [xml]$issue_skeleton = '<div class="row"><div class="col-sm-9"></div><div class="col-sm-3"></div></div>'
        $div_issue_left = $issue_skeleton.SelectSingleNode('//div[@class="col-sm-9"]')
        $div_issue_right = $issue_skeleton.SelectSingleNode('//div[@class="col-sm-3"]')
        $br = $issue_skeleton.CreateNode([System.Xml.XmlNodeType]::Element, $issue_skeleton.Prefix, 'br', $issue_skeleton.NamespaceURI);
        ################### CREATE ELEMENTS FOR DETAILED ISSUE ####################
        #Create h6 element object
        $h6_attributes = [ordered]@{
            class = 'card-title text-justify font-weight-bold';
        }
        $h6_element = @{
            tagname = 'h6';
            attributes = $h6_attributes;
            CreateTextNode = 'Description:'
            own_template = $issue_skeleton;
        }
        #Create P element object
        $p_attributes = [ordered]@{
            class = 'card-text';
        }
        $p_element = @{
            tagname = 'p';
            attributes = $p_attributes;
            own_template = $issue_skeleton;
        }
        #Create span element object
        $span_attributes = [ordered]@{
            class = 'badge bg-primary';
        }
        $span_element = @{
            tagname = 'span';
            attributes = $span_attributes;
            own_template = $issue_skeleton;
        }
        #Create a element object for references
        $ahref_reference_attributes = [ordered]@{
            class = 'external-link';
            target = '_blank';
            href = $null;
        }
        $ahref_reference_element = @{
            tagname = 'a';
            attributes = $ahref_reference_attributes;
            innerText = $null;
            own_template = $issue_skeleton;
        }
        #Create a element role button object
        $ahref_button_attributes = [ordered]@{
            class = 'btn btn-primary details-button float-end';
            id = 'artifact-details';
            role = 'button';
            'data-issue' = $null;
            href = '#';
        }
        $ahref_button_element = @{
            tagname = 'a';
            attributes = $ahref_button_attributes;
            own_template = $issue_skeleton;
        }
        #Right div
        #Create ul and li tag elements
        $ul = $issue_skeleton.CreateElement("ul")
        $li = $issue_skeleton.CreateElement("li")
        #Create description, references, etc.. elements
        $h6_description = New-HtmlTag @h6_element
        #Create rationale element
        $h6_element.CreateTextNode = 'Rationale:'
        $h6_rationale = New-HtmlTag @h6_element
        #Create impact element
        $h6_element.CreateTextNode = 'Impact:'
        $h6_impact = New-HtmlTag @h6_element
        #Create remediation element
        $h6_element.CreateTextNode = 'Remediation:'
        $h6_remediation = New-HtmlTag @h6_element
        #Create references element
        $h6_element.CreateTextNode = 'References:'
        $h6_reference = New-HtmlTag @h6_element
        #Create compliance element
        $h6_element.CreateTextNode = 'Compliance:'
        $h6_compliance = New-HtmlTag @h6_element
    }
    Process{
        #Compile issue
        #Get id suffix from issue
        $id_suffix = $issue.id_suffix1.Replace(' ','_')
        $random = Get-Random -Minimum 20 -Maximum 400
        #Create new ID
        $id = ("{0}_{1}" -f $id_suffix, $random)
        #Get description
        #$new_p_element = $p_element.Clone()
        $card_description = New-HtmlTag @p_element
        if($null -ne $issue.description -and $issue.description.Length -gt 0){
            #Convert description to html
            try{
                $text = Remove-BlankAndTab -text $issue.description
                $outHtml = Convert-MarkDownToHtml $text -UseAdvancedExtensions
                if($null -ne $outHtml){
                    $xml = New-Object -TypeName System.Xml.XmlDocument
                    $outHtml = ("<div>{0}</div>" -f $outHtml)
                    [void]$xml.LoadXml($outHtml)
                    $card_description = $issue_skeleton.ImportNode($xml.get_DocumentElement(), $True)
                }
            }
            catch{
                Write-Verbose $_.Exception
                [void]$card_description.AppendChild($issue_skeleton.CreateTextNode($issue.description.ToString()))
            }
        }
        else{
            [void]$card_description.AppendChild($issue_skeleton.CreateTextNode('No description available.'))
        }
        #Add to div
        [void]$div_issue_left.AppendChild($h6_description)
        [void]$div_issue_left.AppendChild($card_description)
        #Check for rationale
        if($null -ne $issue.psobject.properties.Item('rationale') -and $null -ne $issue.rationale -and $issue.rationale.Length -gt 0){
            #Convert description to html
            try{
                $text = Remove-BlankAndTab -text $issue.rationale
                $outHtml = Convert-MarkDownToHtml $text -UseAdvancedExtensions
                if($null -ne $outHtml){
                    $xml = New-Object -TypeName System.Xml.XmlDocument
                    $outHtml = ("<div>{0}</div>" -f $outHtml)
                    [void]$xml.LoadXml($outHtml)
                    $card_rationale = $issue_skeleton.ImportNode($xml.get_DocumentElement(), $True)
                }
            }
            catch{
                Write-Verbose $_.Exception
                $card_rationale = New-HtmlTag @p_element
                [void]$card_rationale.AppendChild($issue_skeleton.CreateTextNode($issue.rationale.ToString()))
            }
            [void]$div_issue_left.AppendChild($h6_rationale)
            [void]$div_issue_left.AppendChild($card_rationale)
        }
        #Check for impact
        if($null -ne $issue.psobject.properties.Item('impact') -and $null -ne $issue.impact -and $issue.impact.Length -gt 0){
            #Convert description to html
            try{
                $text = Remove-BlankAndTab -text $issue.impact
                $outHtml = Convert-MarkDownToHtml $text -UseAdvancedExtensions
                if($null -ne $outHtml){
                    $xml = New-Object -TypeName System.Xml.XmlDocument
                    $outHtml = ("<div>{0}</div>" -f $outHtml)
                    [void]$xml.LoadXml($outHtml)
                    $card_impact = $issue_skeleton.ImportNode($xml.get_DocumentElement(), $True)
                }
            }
            catch{
                Write-Verbose $_.Exception
                $card_impact = New-HtmlTag @p_element
                [void]$card_impact.AppendChild($issue_skeleton.CreateTextNode($issue.impact.ToString()))
            }
            [void]$div_issue_left.AppendChild($h6_impact)
            [void]$div_issue_left.AppendChild($card_impact)
        }
        #Check for remediation
        if($null -ne $issue.psobject.properties.Item('remediation') -and $null -ne $issue.remediation -and $issue.remediation.Length -gt 0){
            #Convert description to html
            try{
                $text = Remove-BlankAndTab -text $issue.remediation
                $outHtml = Convert-MarkDownToHtml $text -UseAdvancedExtensions
                if($null -ne $outHtml){
                    $xml = New-Object -TypeName System.Xml.XmlDocument
                    $outHtml = ("<div>{0}</div>" -f $outHtml)
                    [void]$xml.LoadXml($outHtml)
                    $card_remediation = $issue_skeleton.ImportNode($xml.get_DocumentElement(), $True)
                }
            }
            catch{
                Write-Verbose $_.Exception
                $card_remediation = New-HtmlTag @p_element
                [void]$card_remediation.AppendChild($issue_skeleton.CreateTextNode($issue.remediation.ToString()))
            }
            [void]$div_issue_left.AppendChild($h6_remediation)
            [void]$div_issue_left.AppendChild($card_remediation)
        }
        #Get references
        $card_references_links = New-HtmlTag @p_element
        if($issue.references.Count -gt 0){
            if($null -ne $card_references_links){
                foreach($reference in $issue.references){
                    if($reference.length -gt 0){
                        $new_a = $ahref_reference_element.Clone()
                        $new_a.innerText = $reference
                        $new_a.attributes.href = ('{0}' -f $reference)
                        $a_href = New-HtmlTag @new_a
                        if($a_href){
                            [void]$card_references_links.AppendChild($a_href)
                            [void]$card_references_links.AppendChild($br.Clone())
                        }
                    }
                }
            }
        }
        else{
            [void]$card_references_links.AppendChild($issue_skeleton.CreateTextNode("No references available."))
        }
        #Add to div
        [void]$div_issue_left.AppendChild($h6_reference)
        [void]$div_issue_left.AppendChild($card_references_links)
        #Add compliance
        $compliance = [bool]($issue.PSobject.Properties.name -match "compliance")
        if($compliance){
            $card_compliance_p = New-HtmlTag @p_element
            foreach($reference in $issue.compliance){
                if($reference -is [system.object] -and $reference.psobject.Properties.Name -contains "name"){
                    if($reference.PSObject.Properties.name -match "name"){
                        $internal_span = $span_element.Clone()
                        $internal_span.attributes.class = 'badge bg-primary'
                        $internal_span.innerText = $reference.name.ToString()
                        $span_name = New-HtmlTag @internal_span
                        #Add to P element
                        if($span_name){
                            [void]$card_compliance_p.AppendChild($span_name)
                        }
                    }
                    if($reference.PSObject.Properties.name -match "version"){
                        $internal_span = $span_element.Clone()
                        $internal_span.attributes.class = 'badge bg-info'
                        $internal_span.innerText = $reference.version.ToString()
                        $span_version = New-HtmlTag @internal_span
                        #Add to P element
                        if($span_version){
                            [void]$card_compliance_p.AppendChild($span_version)
                        }
                    }
                    if($reference.PSObject.Properties.name -match "reference"){
                        $internal_span = $span_element.Clone()
                        $internal_span.attributes.class = 'badge bg-success'
                        $internal_span.innerText = $reference.reference.ToString()
                        $span_reference = New-HtmlTag @internal_span
                        #Add to P element
                        if($span_reference){
                            [void]$card_compliance_p.AppendChild($span_reference)
                        }
                    }
                    #Add BR element
                    [void]$card_compliance_p.AppendChild($br.Clone())
                }
                elseif($reference -is [System.Collections.ArrayList]){
                    foreach($ref in $reference){
                        if($ref.length -gt 0){
                            $internal_span = $span_element.Clone()
                            $internal_span.attributes.class = 'badge bg-primary'
                            $internal_span.innerText = $ref.ToString()
                            $span_name = New-HtmlTag @internal_span
                            #Add to P element
                            if($span_name){
                                [void]$card_compliance_p.AppendChild($span_name)
                                #Add BR element
                                [void]$card_compliance_p.AppendChild($br.Clone())
                            }
                        }
                    }
                }
                elseif ($reference -is [System.Object[]]){
                    foreach($ref in $reference){
                        if($ref.length -gt 0){
                            $internal_span = $span_element.Clone()
                            $internal_span.attributes.class = 'badge bg-primary'
                            $internal_span.innerText = $ref.ToString()
                            $span_name = New-HtmlTag @internal_span
                            #Add to P element
                            if($span_name){
                                [void]$card_compliance_p.AppendChild($span_name)
                                #Add BR element
                                [void]$card_compliance_p.AppendChild($br.Clone())
                            }
                        }
                    }
                }
            }
            #Add to div
            [void]$div_issue_left.AppendChild($h6_compliance)
            [void]$div_issue_left.AppendChild($card_compliance_p)
        }
        #Right div
        $checked = $li.Clone()
        $checked.InnerText = ("{0} checked: {1}" -f $dashboard_name, $issue.resources)
        $flagged = $li.Clone()
        #$affected_rsrc = @($issue.affected_resources).Count
        $flagged.InnerText = ("{0} flagged: {1}" -f $dashboard_name, $issue.affected_resources_count)
        #Add to ul
        [void]$ul.AppendChild($checked)
        [void]$ul.AppendChild($flagged)
        #Add to right div
        [void]$div_issue_right.AppendChild($ul)
        #Get new Issue Card
        $params = @{
            collapsibleCard = $True;
            issueCard = $True;
            card_class = 'monkey-issue-card';
            card_header_class = 'card-header-blue';
            title_header = $issue.issue_name;
            span_class = $level;
            body = $issue_skeleton;
            WithFooter= $True;
            card_footer_class = 'clearfix';
        }
        $my_card = Get-HtmlCard @params
        if($my_card){
            #Add reference to accordion link
            $card_accordionLink = $my_card.SelectSingleNode('//a[contains(@class,"accordion-toggle")]')
            if($card_accordionLink){
                [void]$card_accordionLink.SetAttribute('data-bs-parent',('#{0}' -f $id))
                [void]$card_accordionLink.SetAttribute('href',('#{0}' -f $id))
            }
            #Get accordion body
            $accordion_div_body = $my_card.SelectSingleNode('//div[contains(@class,"collapse")]')
            if($accordion_div_body){
                [void]$accordion_div_body.SetAttribute('data-bs-parent',('#{0}' -f $id))
                [void]$accordion_div_body.SetAttribute('id',$id)
            }
            #Add Card footer
            $card_footer = $my_card.SelectSingleNode('//div[contains(@class,"card-footer")]')
            #Add button
            if($issue.level -ne 'Good'){
                $new_span_params = $span_element.Clone()
                $new_span_params.attributes.class = 'btn-label'
                #Create i element
                $params = @{
                    tagname = "i";
                    classname = "bi bi-cloud-check";
                    empty = $True;
                    own_template = $my_card;
                }
                $i_element = New-HtmlTag @params
                #Create span element and add i element
                $new_span_params.appendObject = $i_element
                $new_span_params.own_template = $my_card
                $span_issue = New-HtmlTag @new_span_params
                #create a button and add span element
                $a_button_params = $ahref_button_element.Clone()
                $a_button_params.appendObject = $span_issue
                $a_button_params.own_template = $my_card
                #$a_button_params.CreateTextNode = 'Details'
                $a_button_params.attributes.'data-issue' = $issue.id_suffix2
                $a_button = New-HtmlTag @a_button_params
                if($a_button){
                    [void]$a_button.AppendChild($my_card.CreateTextNode('Details'))
                }
                #Add button
                [void]$card_footer.AppendChild($a_button)
            }
            #Close i tags
            $i = $my_card.SelectNodes("//i")
            $i | ForEach-Object {$_.InnerText = [string]::Empty}
        }
    }
    End{
        if($my_card){
            return $my_card
        }
    }
}
