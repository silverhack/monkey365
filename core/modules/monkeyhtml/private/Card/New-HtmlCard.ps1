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

Function New-HtmlCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Class name")]
        [String[]]$ClassName,

        [parameter(Mandatory= $false, HelpMessage= "ID card")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "Style card")]
        [String]$Style,

        [parameter(Mandatory= $false, HelpMessage= "Img card")]
        [Switch]$ImgCard,

        [parameter(Mandatory= $false, HelpMessage= "Card Header")]
        [String]$Header,

        [parameter(Mandatory= $false, HelpMessage= "Card Header class")]
        [String[]]$HeaderClass,

        [parameter(Mandatory= $false, HelpMessage= "Header Object")]
        [AllowNull()]
        [Object]$HeaderObject,

        [parameter(Mandatory= $false, HelpMessage= "Card title")]
        [String]$Title,

        [parameter(Mandatory= $false, HelpMessage= "Card subtitle class")]
        [String[]]$TitleClass,

        [parameter(Mandatory= $false, HelpMessage= "Card subtitle")]
        [String]$SubTitle,

        [parameter(Mandatory= $false, HelpMessage= "Card subtitle class")]
        [String[]]$SubTitleClass,

        [parameter(Mandatory= $false, HelpMessage= "Card text")]
        [String]$CardText,

        [parameter(Mandatory= $false, HelpMessage= "Body class name")]
        [String[]]$BodyClass,

        [parameter(Mandatory= $false, HelpMessage= "Body Object")]
        [AllowNull()]
        [Object]$BodyObject,

        [parameter(Mandatory= $false, HelpMessage= "Footer text")]
        [String]$FooterText,

        [parameter(Mandatory= $false, HelpMessage= "Footer Object")]
        [AllowNull()]
        [Object]$FooterObject,

        [parameter(Mandatory= $false, HelpMessage= "Card footer class")]
        [String[]]$FooterClass,

        [parameter(Mandatory= $false, HelpMessage= "Collapsible Card")]
        [Switch]$Collapsible,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    dynamicparam{
        # set a new dynamic parameter
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        #Add parameters for Microsoft365 instance
        if($null -ne (Get-Variable -Name ImgCard -ErrorAction Ignore)){
            #Create the -ImgSrc string parameter
            $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $_attr_name = New-Object System.Management.Automation.ParameterAttribute
            $_attr_name.Mandatory = $true
            $attributeCollection.Add($_attr_name)
            $_pname = 'ImgSrc'
            $_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($_pname,
            [String], $attributeCollection)
            $paramDictionary.Add($_pname, $_type_dynParam)
        }
        # return the collection of dynamic parameters
        $paramDictionary
    }
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
        #main card
        $card = [xml] '<div class="card"></div>'
        #Add card header
        $cardHeader = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
        #Add extra class to header
        If($PSBoundParameters.ContainsKey('HeaderClass') -and $PSBoundParameters['HeaderClass']){
            $_Class = [String]::Join(' ',$HeaderClass);
            $div_class = ("card-header {0}" -f $_Class)
            [void]$cardHeader.SetAttribute('class',$div_class)
        }
        Else{
            [void]$cardHeader.SetAttribute('class',"card-header")
        }
        #Add card body
        $cardBody = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
        #Add extra class to body
        If($PSBoundParameters.ContainsKey('BodyClass') -and $PSBoundParameters['BodyClass']){
            $_Class = [String]::Join(' ',$BodyClass);
            $div_class = ("card-body {0}" -f $_Class)
            [void]$cardBody.SetAttribute('class',$div_class)
        }
        Else{
            [void]$cardBody.SetAttribute('class',"card-body")
        }
        #Add card footer
        $cardFooter = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
        #Add extra class to footer
        If($PSBoundParameters.ContainsKey('FooterClass') -and $PSBoundParameters['FooterClass']){
            $_Class = [String]::Join(' ',$FooterClass);
            $div_class = ("card-footer {0}" -f $_Class)
            [void]$cardFooter.SetAttribute('class',$div_class)
        }
        Else{
            [void]$cardFooter.SetAttribute('class',"card-footer")
        }
    }
    Process{
        #Set Class name
        If($ClassName){
            $main_node = $card.SelectSingleNode('//div[@class="card"]')
            $_Class = [String]::Join(' ',$ClassName);
            $div_class = ("card {0}" -f $_Class)
            [void]$main_node.SetAttribute('class',$div_class)
        }
        #Set ID card
        If($Id){
            $main_node = $card.SelectSingleNode('//div[contains(@class,"card")]')
            [void]$main_node.SetAttribute('id',$Id)
        }
        #Check if custom style should be added to card
        if($Style){
            $main_node = $card.SelectSingleNode('//div[contains(@class,"card")]')
            [void]$main_node.SetAttribute('style',$Style.ToString())
        }
        #Check if Card img
        If($PSBoundParameters.ContainsKey('ImgCard') -and $PSBoundParameters['ImgCard'].IsPresent){
            $img_element = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'img', $TemplateObject.NamespaceURI);
            [void]$img_element.SetAttribute('class','card-img-top')
            [void]$img_element.SetAttribute('src',$PSBoundParameters['ImgSrc'])
            #Close Img
            [void]$img_element.AppendChild($TemplateObject.CreateWhitespace(""))
            #Add img to the main div
            $main_node = $card.SelectSingleNode('//div[contains(@class,"card")]')
            If($main_node){
                [void]$main_node.AppendChild($img_element)
            }
        }
        #Check if Header object
        If($PSBoundParameters.ContainsKey('HeaderObject')){
            If($HeaderObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "Card header")
                [void]$cardHeader.AppendChild($TemplateObject.ImportNode($HeaderObject.get_DocumentElement(), $True))
            }
            ElseIf($HeaderObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "Card header")
                [void]$cardHeader.AppendChild($TemplateObject.ImportNode($HeaderObject,$True))
            }
            ElseIf($null -eq $HeaderObject){
                Write-Verbose ($Script:messages.EmptyDiv -f "Card header")
                #set blank
                [void]$cardHeader.AppendChild($TemplateObject.CreateTextNode([string]::Empty))
            }
            Else{
                #Add text
                [void]$cardHeader.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['HeaderObject'].ToString()))
            }
        }
        #Check if Card Header
        If($PSBoundParameters.ContainsKey('Header') -and $PSBoundParameters['Header']){
            [void]$cardHeader.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['Header'].ToString()))
        }
        #Check if Card title
        If($PSBoundParameters.ContainsKey('Title') -and $PSBoundParameters['Title']){
            $h5Title = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'h5', $TemplateObject.NamespaceURI);
            If($PSBoundParameters.ContainsKey('TitleClass') -and $PSBoundParameters['TitleClass']){
                $_Class = [String]::Join(' ',$TitleClass);
                $div_class = ("card-title {0}" -f $_Class)
                [void]$h5Title.SetAttribute('class',$div_class)
            }
            Else{
                [void]$h5Title.SetAttribute('class','card-title')
            }
            #Add title
            [void]$h5Title.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['Title'].ToString()))
            #Add to body
            [void]$cardBody.AppendChild($h5Title)
        }
        #Check if Card subtitle
        If($PSBoundParameters.ContainsKey('SubTitle') -and $PSBoundParameters['SubTitle']){
            $h6SubTitle = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'h6', $TemplateObject.NamespaceURI);
            If($PSBoundParameters.ContainsKey('SubTitleClass') -and $PSBoundParameters['SubTitleClass']){
                $_Class = [String]::Join(' ',$SubTitleClass);
                $div_class = ("card-subtitle {0}" -f $_Class)
                [void]$h6SubTitle.SetAttribute('class',$div_class)
            }
            Else{
                [void]$h6SubTitle.SetAttribute('class','card-subtitle')
            }
            #Add title
            [void]$h6SubTitle.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['SubTitle'].ToString()))
            #Add to body
            [void]$cardBody.AppendChild($h6SubTitle)
        }
        #Check if Card text
        If($PSBoundParameters.ContainsKey('CardText') -and $PSBoundParameters['CardText']){
            $pText = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'p', $TemplateObject.NamespaceURI);
            [void]$pText.SetAttribute('class','card-text')
            #Add text
            [void]$pText.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['CardText'].ToString()))
            #Add to body
            [void]$cardBody.AppendChild($pText)
        }
        #Check if Body object
        If($PSBoundParameters.ContainsKey('BodyObject')){
            If($BodyObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "Card body")
                [void]$cardBody.AppendChild($TemplateObject.ImportNode($BodyObject.get_DocumentElement(), $True))
            }
            ElseIf($BodyObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "Card body")
                [void]$cardBody.AppendChild($TemplateObject.ImportNode($BodyObject,$True))
            }
            ElseIf($null -eq $BodyObject){
                Write-Verbose ($Script:messages.EmptyDiv -f "Card body")
                #set blank
                [void]$cardBody.AppendChild($TemplateObject.CreateTextNode([string]::Empty))
            }
            Else{
                #Add text
                [void]$cardBody.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['BodyObject'].ToString()))
            }
        }
        #Check if Card text
        If($PSBoundParameters.ContainsKey('FooterText') -and $PSBoundParameters['FooterText']){
            #Add text
            [void]$cardFooter.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['FooterText'].ToString()))
        }
        #Check if footer object
        If($PSBoundParameters.ContainsKey('FooterObject')){
            If($FooterObject -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "Card footer")
                [void]$cardFooter.AppendChild($TemplateObject.ImportNode($FooterObject.get_DocumentElement(), $True))
            }
            ElseIf($FooterObject -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "Card footer")
                [void]$cardFooter.AppendChild($TemplateObject.ImportNode($FooterObject,$True))
            }
            ElseIf($null -eq $FooterObject){
                Write-Verbose ($Script:messages.EmptyDiv -f "Card footer")
                #set blank
                [void]$cardFooter.AppendChild($TemplateObject.CreateTextNode([string]::Empty))
            }
            Else{
                #Add text
                [void]$cardFooter.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['FooterObject'].ToString()))
            }
        }
    }
    End{
        #Import node
        $card = $TemplateObject.ImportNode($card.DocumentElement,$true);
        #Check if collapsible card
        If($PSBoundParameters.ContainsKey('Collapsible') -and $PSBoundParameters['Collapsible'].IsPresent){
            If($cardHeader.HasChildNodes){
                $newId = ("Monkey{0}" -f [System.Guid]::NewGuid().Guid)
                #Add data-bs-toggle and data-bs-target
                [void]$cardHeader.SetAttribute('data-bs-toggle','collapse');
                #Add data-bs-toggle and data-bs-target
                [void]$cardHeader.SetAttribute('data-bs-target',("#{0}") -f $newId);
                #Add aria-controls
                [void]$cardHeader.SetAttribute('aria-controls',("{0}") -f $newId);
                #Set new div for Body
                $collapsibleDiv = $TemplateObject.CreateNode([System.Xml.XmlNodeType]::Element, $TemplateObject.Prefix, 'div', $TemplateObject.NamespaceURI);
                [void]$collapsibleDiv.SetAttribute('class',"collapse")
                [void]$collapsibleDiv.SetAttribute('id',$newId);
                #Add always body
                [void]$collapsibleDiv.AppendChild($cardBody);
                #Check if footer has childobjects
                If($cardFooter.HasChildNodes){
                    [void]$collapsibleDiv.AppendChild($cardFooter);
                }
                #Add header to card
                [void]$card.AppendChild($cardHeader)
                #Add div to card
                [void]$card.AppendChild($collapsibleDiv)
            }
            Else{
                Write-Warning "Unable to convert card to collapsible card. Header was not found"
            }
        }
        Else{
            #Check if cardHeader must be added
            If($cardHeader.HasChildNodes){
                #Add to card
                [void]$card.AppendChild($cardHeader)
            }
            #Check if cardBody must be added
            If($cardBody.HasChildNodes){
                #Add to card
                [void]$card.AppendChild($cardBody)
            }
            #Check if cardFooter must be added
            If($cardFooter.HasChildNodes){
                #Add to card
                [void]$card.AppendChild($cardFooter)
            }
        }
        #Close potentially divs
        $allDivs = $card.SelectNodes("//div")
        Foreach($div in $allDivs){
            If($div.HasChildNodes -eq $false){
                $div.InnerText = [string]::Empty
            }
        }

        #return Card
        return $card
    }
}
