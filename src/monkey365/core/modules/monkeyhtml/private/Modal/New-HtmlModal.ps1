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
        [parameter(Mandatory= $false, HelpMessage= "ID Modal")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "Style Modal")]
        [String]$Style,

        [parameter(Mandatory= $false, HelpMessage= "Icon class")]
        [String]$IconHeaderClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal extra header class")]
        [String[]]$HeaderClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal header Object")]
        [AllowNull()]
        [Object]$HeaderObject,

        [parameter(Mandatory= $false, HelpMessage= "Modal content extra class")]
        [String[]]$ContentClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal dialog extra class")]
        [String[]]$DialogClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal title")]
        [String]$Title,

        [parameter(Mandatory= $false, HelpMessage= "Modal title extra class")]
        [String[]]$TitleClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal Body class name")]
        [String[]]$BodyClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal Body Object")]
        [AllowNull()]
        [Object]$BodyObject,

        [parameter(Mandatory= $false, HelpMessage= "Footer text")]
        [String]$FooterText,

        [parameter(Mandatory= $false, HelpMessage= "Footer Object")]
        [AllowNull()]
        [Object]$FooterObject,

        [parameter(Mandatory= $false, HelpMessage= "Modal footer class")]
        [String[]]$FooterClass,

        [parameter(Mandatory= $false, HelpMessage= "Modal size")]
        [ValidateSet("small","large","extra")]
        [String]$Size,

        [parameter(Mandatory= $false, HelpMessage= "Add close button")]
        [Switch]$AddCloseButton,

        [parameter(Mandatory= $false, HelpMessage= "Static backdrop")]
        [Switch]$StaticBackdrop,

        [parameter(Mandatory= $false, HelpMessage= "vertically centered modal")]
        [Switch]$Centered,

        [parameter(Mandatory= $false, HelpMessage= "vertically centered scrollable modal")]
        [Switch]$CenteredScrollable,

        [Parameter(Mandatory= $false, HelpMessage="remove modal animation")]
        [Switch]$RemoveAnimation,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Set null
        $modalSize = $null;
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #main modal
        [xml]$modal = '<div class="modal fade"></div>'
        [void]$modal.div.SetAttribute('tabindex',"-1")
        [void]$modal.div.SetAttribute('role',"dialog")
        #Add modal dialog
        $modalDialog = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
        [void]$modalDialog.SetAttribute('role',"document")
        #Add extra class to dialog
        If($PSBoundParameters.ContainsKey('DialogClass') -and $PSBoundParameters['DialogClass']){
            $_Class = [String]::Join(' ',$DialogClass);
            $div_class = ("modal-dialog {0}" -f $_Class)
            [void]$modalDialog.SetAttribute('class',$div_class)
        }
        Else{
            [void]$modalDialog.SetAttribute('class',"modal-dialog")
        }
        #Add modal header
        $modalHeader = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
        #Add extra class to header
        If($PSBoundParameters.ContainsKey('HeaderClass') -and $PSBoundParameters['HeaderClass']){
            $_Class = [String]::Join(' ',$HeaderClass);
            $div_class = ("modal-header {0}" -f $_Class)
            [void]$modalHeader.SetAttribute('class',$div_class)
        }
        Else{
            [void]$modalHeader.SetAttribute('class',"modal-header")
        }
        #Add modal body
        $modalBody = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
        #Add extra class to body
        If($PSBoundParameters.ContainsKey('BodyClass') -and $PSBoundParameters['BodyClass']){
            $_Class = [String]::Join(' ',$BodyClass);
            $div_class = ("modal-body overflow-auto {0}" -f $_Class)
            [void]$modalBody.SetAttribute('class',$div_class)
        }
        Else{
            [void]$modalBody.SetAttribute('class',"modal-body overflow-auto")
        }
        #Add card footer
        $modalFooter = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
        #Add extra class to footer
        If($PSBoundParameters.ContainsKey('FooterClass') -and $PSBoundParameters['FooterClass']){
            $_Class = [String]::Join(' ',$FooterClass);
            $div_class = ("modal-footer {0}" -f $_Class)
            [void]$modalFooter.SetAttribute('class',$div_class)
        }
        Else{
            [void]$modalFooter.SetAttribute('class',"modal-footer")
        }
        #Check if remove animation should be removed to modal
        If($RemoveAnimation){
            $main_modal = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_modal.SetAttribute('class',"modal")
        }
        #Add modal content
        $modalContent = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'div', $modal.NamespaceURI);
        #Add extra class to content
        If($PSBoundParameters.ContainsKey('ContentClass') -and $PSBoundParameters['ContentClass']){
            $_Class = [String]::Join(' ',$ContentClass);
            $div_class = ("modal-content {0}" -f $_Class)
            [void]$modalContent.SetAttribute('class',$div_class)
        }
        Else{
            [void]$modalContent.SetAttribute('class',"modal-content")
        }
        #Check modal size
        If($Size){
            Switch ($Size.ToLower()) {
                'small'{
                    $modalSize = "modal-sm"
                }
                'large'{
                    $modalSize = "modal-lg"
                }
                'extra'{
                    $modalSize = "modal-xl"
                }
            }
            $current_class = $modalDialog.class
            $div_class = ('{0} {1}' -f $current_class,$modalSize)
            [void]$modalDialog.SetAttribute('class',$div_class)
        }
        #Check if a static backdrop class must be added
        If($StaticBackdrop){
            $main_modal = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_modal.SetAttribute('data-bs-backdrop',"static")
            [void]$main_modal.SetAttribute('data-bs-keyboard',"false")
        }
        #Check if a centered or centered scrollable class should be added
        If($Centered){
            $dialog_div = $modal.SelectSingleNode('//div[contains(@class,"modal-dialog")]')
            $current_class = $dialog_div.class
            $div_class = ('{0} modal-dialog-centered' -f $current_class)
            [void]$dialog_div.SetAttribute('class',$div_class)
        }
        #Check if an scrollable class should be added
        If($CenteredScrollable){
            $dialog_div = $modal.SelectSingleNode('//div[contains(@class,"modal-dialog")]')
            $current_class = $dialog_div.class
            $div_class = ('{0} modal-dialog-centered modal-dialog-scrollable' -f $current_class)
            [void]$dialog_div.SetAttribute('class',$div_class)
        }
    }
    Process{
        #Set ID card
        If($Id){
            $myId = $Id
            $main_node = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_node.SetAttribute('id',$myId)
            #Set aria labelled
            [void]$main_node.SetAttribute('aria-labelledby',("{0}Label" -f $myId))
        }
        Else{
            #Set random number
            $rnd = Get-Random -Maximum 1500 -Minimum 1
            $myId = ("monkey_modal_{0}" -f $rnd)
            $main_node = $modal.SelectSingleNode('//div[contains(@class,"modal")]')
            [void]$main_node.SetAttribute('id',("{0}" -f $myId))
            #Set aria labelled
            [void]$main_node.SetAttribute('aria-labelledby',("{0}Label" -f $myId))
        }
        #Check if a close button must be added
        If($AddCloseButton){
            $close_button = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'button', $modal.NamespaceURI);
            [void]$close_button.SetAttribute('type',"button")
            [void]$close_button.SetAttribute('class',"btn btn-secondary")
            [void]$close_button.SetAttribute('data-bs-dismiss',"modal")
            #set close string to button
            [void]$close_button.AppendChild($modal.CreateTextNode("Close"))
            #Add button to footer
            [void]$modalFooter.AppendChild($close_button)
        }
        #Check if Header object
        If($PSBoundParameters.ContainsKey('HeaderObject')){
            If($HeaderObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "Card header")
                [void]$cardHeader.AppendChild($card.ImportNode($HeaderObject.get_DocumentElement(), $True))
            }
            ElseIf($HeaderObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "Card header")
                [void]$cardHeader.AppendChild($card.ImportNode($HeaderObject,$True))
            }
            ElseIf($null -eq $HeaderObject){
                Write-Verbose ($Script:messages.EmptyDiv -f "Card header")
                #set blank
                [void]$cardHeader.AppendChild($card.CreateTextNode([string]::Empty))
            }
            Else{
                #Add text
                [void]$cardHeader.AppendChild($card.CreateTextNode($PSBoundParameters['HeaderObject'].ToString()))
            }
        }
        #Check if Body object
        If($PSBoundParameters.ContainsKey('BodyObject')){
            If($BodyObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "Modal body")
                [void]$modalBody.AppendChild($modal.ImportNode($BodyObject.get_DocumentElement(), $True))
            }
            ElseIf($BodyObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "Card body")
                [void]$modalBody.AppendChild($modal.ImportNode($BodyObject,$True))
            }
            ElseIf($null -eq $BodyObject){
                Write-Verbose ($Script:messages.EmptyDiv -f "Modal body")
                #set blank
                [void]$modalBody.AppendChild($modal.CreateTextNode([string]::Empty))
            }
            Else{
                #Add text
                [void]$modalBody.AppendChild($modal.CreateTextNode($PSBoundParameters['BodyObject'].ToString()))
            }
        }
        #Check if modal footer text
        If($PSBoundParameters.ContainsKey('FooterText') -and $PSBoundParameters['FooterText']){
            #Add text
            [void]$modalFooter.AppendChild($modal.CreateTextNode($PSBoundParameters['FooterText'].ToString()))
        }
        #Check if should add footer elements
        If($PSBoundParameters.ContainsKey('FooterObject')){
            If($FooterObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "modal footer")
                [void]$modalFooter.AppendChild($modal.ImportNode($FooterObject.get_DocumentElement(), $True))
            }
            ElseIf($FooterObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "modal footer")
                [void]$modalFooter.AppendChild($modal.ImportNode($FooterObject,$True))
            }
            Else{
                #Add text
                [void]$modalFooter.AppendChild($modal.CreateTextNode($PSBoundParameters['FooterObject'].ToString()))
            }
        }
        #check if an icon must be added
        If($IconHeaderClass){
            $icon = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'i', $modal.NamespaceURI);
            [void]$icon.SetAttribute('class',$IconHeaderClass)
            #Add icon to div
            [void]$modalHeader.AppendChild($icon)
        }
        #Check if modal title
        If($PSBoundParameters.ContainsKey('Title') -and $PSBoundParameters['Title']){
            $h5Title = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'h5', $modal.NamespaceURI);
            If($PSBoundParameters.ContainsKey('TitleClass') -and $PSBoundParameters['TitleClass']){
                $_Class = [String]::Join(' ',$TitleClass);
                $div_class = ("modal-title-header {0}" -f $_Class)
                [void]$h5Title.SetAttribute('class',$div_class)
            }
            Else{
                [void]$h5Title.SetAttribute('class','modal-title-header')
            }
            #Add title
            [void]$h5Title.AppendChild($modal.CreateTextNode($PSBoundParameters['Title'].ToString()))
            #Add id
            [void]$h5Title.SetAttribute('id',("{0}Label" -f $myId))
            #Add to header
            [void]$modalHeader.AppendChild($h5Title)
        }
        #Add close button
        $close_button = $modal.CreateNode([System.Xml.XmlNodeType]::Element, $modal.Prefix, 'button', $modal.NamespaceURI);
        [void]$close_button.SetAttribute('type',"button")
        [void]$close_button.SetAttribute('class',"btn-close")
        [void]$close_button.SetAttribute('data-bs-dismiss',"modal")
        [void]$close_button.SetAttribute('aria-label',"Close")
        #set empty string to close button
        [void]$close_button.AppendChild($modal.CreateTextNode([string]::Empty))
        #Add button to footer
        [void]$modalHeader.AppendChild($close_button)
        #force close i
        $all_i = $modal.SelectNodes("//i")
        ForEach($i in $all_i){
            [void]$i.AppendChild($modal.CreateWhitespace(""))
        }
        #Close potentially divs
        $allDivs = $modal.SelectNodes("//div")
        ForEach($div in $allDivs){
            If($div.HasChildNodes -eq $false){
                $div.InnerText = [string]::Empty
            }
        }
        #Compile modal
        #Add comment
        $comment = $modal.CreateComment('Content');
        [void]$modalContent.PrependChild($comment);
        #Add modal header, body and footer into modal content
        #Add comment
        $comment = $modal.CreateComment('Modal Header');
        [void]$modalHeader.PrependChild($comment);
        [void]$modalContent.AppendChild($modalHeader);
        #Add comment
        $comment = $modal.CreateComment('Modal Body');
        [void]$modalBody.PrependChild($comment);
        [void]$modalContent.AppendChild($modalBody);
        #Check if modal footer must be added
        If($modalFooter.HasChildNodes){
            #Add comment
            $comment = $modal.CreateComment('Modal Footer');
            [void]$modalFooter.PrependChild($comment);
            #Add to modal
            [void]$modalContent.AppendChild($modalFooter)
        }
        #Add modal content into modal dialog
        #Add comment
        $comment = $modal.CreateComment('Modal dialog');
        [void]$modalDialog.PrependChild($comment);
        [void]$modalDialog.AppendChild($modalContent)
        #Add dialog to main modal
        [void]$modal.DocumentElement.AppendChild($modalDialog);

    }
    End{
        #Close i tags
        $i = $modal.SelectNodes("//i")
        $i | ForEach-Object {[void]$_.AppendChild($modal.CreateWhitespace(""))}
        #Import node
        $newModal = $TemplateObject.ImportNode($modal.DocumentElement,$true);
        return $newModal
    }
}
