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

Function New-HtmlModal{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlModal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_header_class,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_icon_header_class,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_body_class,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_content_class,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_footer_class,

            [parameter(Mandatory= $false, HelpMessage= "modal size")]
            [ValidateSet("small","large","extra")]
            [String]$modal_size,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_title,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$modal_title_class,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Add footer")]
            [Switch]$WithFooter,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Add close button")]
            [Switch]$addCloseButton,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="static backdrop modal")]
            [Switch]$static_backdrop,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="vertically centered modal")]
            [Switch]$centered,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="vertically centered scrollable modal")]
            [Switch]$centered_scrollable,

            [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="remove modal animation")]
            [Switch]$removeAnimation,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [string]$id_modal,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [object]$body,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [object]$footer_object
    )
    Begin{
        $modal = [xml] '<div class="modal fade" tabindex="-1" role="dialog" id="my_modal"><div class="modal-dialog" role="document"><div class="modal-content"><div class="modal-header"/><div class="modal-body"/></div></div></div>'
        #Check if remove animation should be removed to modal
        if($removeAnimation){
            $main_modal = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_modal.SetAttribute('class',"modal")
        }
        #Check if a footer should be added
        if($WithFooter){
            $footer_div = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
            if($modal_footer_class){
                $div_class = ('modal-footer {0}' -f $modal_footer_class)
            }
            else{
                $div_class = 'modal-footer'
            }
            [void]$footer_div.SetAttribute('class',$div_class)
            #Check if should add a close button
            if($addCloseButton){
                $close_button = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'button', $modal.NamespaceURI);
                [void]$close_button.SetAttribute('type',"button")
                [void]$close_button.SetAttribute('class',"btn btn-secondary")
                [void]$close_button.SetAttribute('data-bs-dismiss',"modal")
                #set close string to button
                [void]$close_button.AppendChild($modal.CreateTextNode("Close"))
                #Add button to footer
                [void]$footer_div.AppendChild($close_button)
            }
            #Check if should add footer elements
            if($PSBoundParameters.ContainsKey('footer_object')){
                if($footer_object -is [System.Xml.XmlDocument]){
                    Write-Verbose ($Script:messages.AppendDocElementTo -f "modal footer")
                    [void]$footer_div.AppendChild($modal.ImportNode($footer_object.get_DocumentElement(), $True))
                }
                elseif($footer_object -is [System.Xml.XmlElement]){
                    Write-Verbose ($Script:messages.AppendXmlElementTo -f "modal footer")
                    [void]$footer_div.AppendChild($modal.ImportNode($footer_object,$True))
                }
            }
            #Add footer to the end
            $div_content = $modal.SelectSingleNode('//div[@class="modal-content"]')
            [void]$div_content.AppendChild($footer_div)
        }
        #Check if custom class should be added to modal content class
        if($modal_content_class){
            $div_content = $modal.SelectSingleNode('//div[@class="modal-content"]')
            $current_class = $div_content.class
            $div_class = ('{0} {1}' -f $current_class, $modal_content_class)
            [void]$div_content.SetAttribute('class',$div_class)
        }
        #Check if custom id should be added to modal
        if($id_modal){
            $main_modal = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_modal.SetAttribute('id',$id_modal.ToString())
        }
        #Check if custom header class should be added
        if($modal_header_class){
            $header_node = $modal.SelectSingleNode('//div[@class="modal-header"]')
            $current_class = $header_node.class
            $div_class = ('{0} {1}' -f $current_class, $modal_header_class)
            [void]$header_node.SetAttribute('class',$div_class)
        }
        #Check if custom body class should be added
        if($modal_body_class){
            $body_node = $modal.SelectSingleNode('//div[@class="modal-body"]')
            $current_class = $body_node.class
            $div_class = ('{0} {1}' -f $current_class, $modal_body_class)
            [void]$body_node.SetAttribute('class',$div_class)
        }
        #Check modal size
        if($modal_size){
            $dialog_div = $modal.SelectSingleNode('//div[@class="modal-dialog"]')
            if($modal_size -eq "small"){
                $size = "modal-sm"
            }
            elseif($modal_size -eq "large"){
                $size = "modal-lg"
            }
            else{
                $size = "modal-xl"
            }
            $current_class = $dialog_div.class
            $div_class = ('{0} {1}' -f $current_class,$size)
            [void]$dialog_div.SetAttribute('class',$div_class)
        }
        #Check if a static backdrop class should be added
        if($static_backdrop){
            $main_modal = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_modal.SetAttribute('data-bs-backdrop',"static")
            [void]$main_modal.SetAttribute('data-bs-keyboard',"false")
        }
        #Check if a centered or centered scrollable class should be added
        if($centered -or $centered_scrollable){
            if($centered){
                $dialog_div = $modal.SelectSingleNode('//div[@class="modal-dialog"]')
                $current_class = $dialog_div.class
                $div_class = ('{0} modal-dialog-centered' -f $current_class)
                [void]$dialog_div.SetAttribute('class',$div_class)
            }
            #Check if an scrollable class should be added
            elseif($centered_scrollable){
                $dialog_div = $modal.SelectSingleNode('//div[@class="modal-dialog"]')
                $current_class = $dialog_div.class
                $div_class = ('{0} modal-dialog-centered modal-dialog-scrollable' -f $current_class)
                [void]$dialog_div.SetAttribute('class',$div_class)
            }
        }
    }
    Process{
        #Get header div
        $header_node = $modal.SelectSingleNode('//div[@class="modal-header"]')
        #check if an icon should be added
        if($modal_icon_header_class){
            $icon = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'i', $modal.NamespaceURI);
            [void]$icon.SetAttribute('class',$modal_icon_header_class)
            #Add icon to div
            [void]$header_node.AppendChild($icon)
        }
        #Add title name
        $h5_title = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'h5', $modal.NamespaceURI);
        if($modal_title_class){
            [void]$h5_title.SetAttribute('class',("modal-title-header {0}" -f $modal_title_class))
        }
        else{
            [void]$h5_title.SetAttribute('class',"modal-title-header")
        }
        if($modal_title){
            #Set text
            $h5_title.InnerText = $modal_title
        }
        else{
            $h5_title.InnerText = "modal title"
        }
        #Add title to div
        [void]$header_node.AppendChild($h5_title)
        #Add close button
        $close_button = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'button', $modal.NamespaceURI);
        [void]$close_button.SetAttribute('type',"button")
        [void]$close_button.SetAttribute('class',"btn-close")
        [void]$close_button.SetAttribute('data-bs-dismiss',"modal")
        [void]$close_button.SetAttribute('aria-label',"Close")
        #set empty string to close button
        [void]$close_button.AppendChild($modal.CreateTextNode([string]::Empty))
        #Add button to footer
        [void]$header_node.AppendChild($close_button)
        #Check if should add body elements
        if($PSBoundParameters.ContainsKey('body')){
            #Get body from main xml
            $modal_body = $modal.SelectSingleNode('//div[contains(@class,"modal-body")]')
            if($body -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "modal body")
                [void]$modal_body.AppendChild($modal.ImportNode($body.get_DocumentElement(), $True))
            }
            elseif($body -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "modal body")
                [void]$modal_body.AppendChild($modal.ImportNode($body,$True))
            }
        }
        else{
            #Get body from modal
            $modal_body = $modal.SelectSingleNode('//div[contains(@class,"modal-body")]')
            Write-Verbose ($Script:messages.EmptyDiv -f "modal body")
            #set blank
            [void]$modal_body.AppendChild($modal.CreateTextNode([string]::Empty))
        }
        #force close i
        $all_i = $modal.SelectNodes("//i")
        foreach($i in $all_i){
            [void]$i.AppendChild($modal.CreateWhitespace(""))
        }
        #Add comment
        $comment = $modal.CreateComment('Content')
        $dialog = $modal.SelectSingleNode('//div[contains(@class,"modal-dialog")]')
        [void]$dialog.PrependChild($comment);
        $comment = $modal.CreateComment('Header')
        $dialog = $modal.SelectSingleNode('//div[contains(@class,"modal-header")]')
        [void]$dialog.PrependChild($comment);
        $comment = $modal.CreateComment('Body')
        $dialog = $modal.SelectSingleNode('//div[contains(@class,"modal-body")]')
        [void]$dialog.PrependChild($comment);
        #Add footer comment
        $comment = $modal.CreateComment('Footer')
        $dialog = $modal.SelectSingleNode('//div[contains(@class,"modal-footer")]')
        [void]$dialog.PrependChild($comment);
    }
    End{
        return $modal
    }
}

