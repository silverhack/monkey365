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

Function Get-HtmlCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$id_card,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_header_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_body_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_body_id,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_footer_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$accordion_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_category,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$title_header,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$subtitle,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$img,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$i_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$span_class,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$card_style,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$body,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$footer,

        [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Add footer")]
        [Switch]
        $WithFooter,

        [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Accordion card")]
        [Switch]$collapsibleCard,

        [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Accordion card")]
        [Switch]$issueCard,

        [Parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="Accordion card")]
        [Switch]$defaultCard
    )
    Begin{
        #main card
        [xml]$card = '<div class="card"><div class="card-header"></div><div class="card-body"></div></div>'
        #Check if a footer should be added
        if($WithFooter){
            $footer_div = $card.CreateNode([System.Xml.XmlNodeType]::Element, $card.Prefix, 'div', $card.NamespaceURI);
            if($card_footer_class){
                $div_class = ('card-footer {0}' -f $card_footer_class)
            }
            else{
                $div_class = 'card-footer'
            }
            [void]$footer_div.SetAttribute('class',$div_class)
            #Add footer to the end
            [void]$card.div.AppendChild($footer_div)
        }
        #Check if custom class should be added to main class
        if($card_class){
            $main_node = $card.SelectSingleNode('//div[@class="card"]')
            $div_class = ('card {0}' -f $card_class)
            [void]$main_node.SetAttribute('class',$div_class)
        }
        #Check if custom id should be added to card
        if($id_card){
            $main_node = $card.SelectSingleNode('//div[contains(@class,"card")]')
            [void]$main_node.SetAttribute('id',$id_card.ToString())
        }
        #Check if custom style should be added to card
        if($card_style){
            $main_node = $card.SelectSingleNode('//div[contains(@class,"card")]')
            [void]$main_node.SetAttribute('style',$card_style.ToString())
        }
        #Check if custom header class should be added
        if($card_header_class){
            $header_node = $card.SelectSingleNode('//div[@class="card-header"]')
            $div_class = ('card-header {0}' -f $card_header_class)
            [void]$header_node.SetAttribute('class',$div_class)
        }
        #Check if custom body class should be added
        if($card_body_class){
            $body_node = $card.SelectSingleNode('//div[@class="card-body"]')
            $div_class = ('card-body {0}' -f $card_body_class)
            [void]$body_node.SetAttribute('class',$div_class)
        }
        #Check if custom id body should be added
        if($card_body_id){
            $body_node = $card.SelectSingleNode('//div[@class="card-body"]')
            [void]$body_node.SetAttribute('id',$card_body_id)
        }
        if($issueCard){
            #Check if issue title and span
            $header_div = $card.SelectSingleNode('//div[contains(@class,"card-header")]')
            if($span_class){
                $span_element = $card.CreateNode([System.Xml.XmlNodeType]::Element, $card.Prefix, 'span', $card.NamespaceURI);
                [void]$span_element.SetAttribute('class',$span_class.ToString())
                $span_element.InnerText = [string]::Empty
            }
            if($title_header -and $collapsibleCard){
                #Create a element
                $a_element = $card.CreateNode([System.Xml.XmlNodeType]::Element, $card.Prefix, 'a', $card.NamespaceURI);
                [void]$a_element.SetAttribute('class','accordion-toggle collapsed')
                [void]$a_element.SetAttribute('aria-expanded','false')
                [void]$a_element.SetAttribute('data-bs-parent','')
                [void]$a_element.SetAttribute('data-bs-toggle','collapse')
                [void]$a_element.SetAttribute('href',[string]::Empty)
                if($span_element){
                    [void]$a_element.AppendChild($span_element)
                }
                #Create text node
                [void]$a_element.AppendChild($card.CreateTextNode($title_header.ToString()))
                #Append to header
                [void]$header_div.AppendChild($a_element)
            }
            else{
                if($span_element){
                    [void]$header_div.AppendChild($span_element)
                }
                #Add text to div
                [void]$header_div.AppendChild($card.CreateTextNode($title_header.ToString()))
            }
        }
        #Check if accordion card
        if($collapsibleCard){
            #Select body
            $body_div = $card.SelectSingleNode('//div[contains(@class,"card-body")]')
            #Select footer
            $footer_div = $card.SelectSingleNode('//div[contains(@class,"card-footer")]')
            #create new div element and add attributes
            $new_div = $card.CreateNode([System.Xml.XmlNodeType]::Element, $card.Prefix, 'div', $card.NamespaceURI);
            if($accordion_class){
                $div_class = ('collapse {0}' -f $accordion_class)
            }
            else{
                $div_class = 'collapse'
            }
            [void]$new_div.SetAttribute('class',$div_class)
            #add new element
            [void]$body_div.ParentNode.AppendChild($new_div)
            #remove old element
            [void]$body_div.ParentNode.RemoveChild($body_div)
            #add old body into the new accordion element
            [void]$new_div.AppendChild($body_div)
            #Add old footer if exists
            if($footer_div){
                [void]$new_div.AppendChild($footer_div)
            }
        }
        if($defaultCard){
            #Check if card category
            if($card_category){
                $category = $card.CreateElement("h5")
                [void]$category.SetAttribute('class','card-category')
                $category.InnerText = $card_category
                #Add card category to div
                $card_header = $card.SelectSingleNode('//div[contains(@class,"card-header")]')
                [void]$card_header.PrependChild($category)
            }
            #Check if title header
            if($title_header){
                #create new div element and add attributes
                $card_title = $card.CreateNode([System.Xml.XmlNodeType]::Element, $card.Prefix, 'div', $card.NamespaceURI);
                #Set div attribute
                [void]$card_title.SetAttribute('class','card-title')
                $header = $card.CreateElement("h3")
                [void]$header.SetAttribute('class','title-header')
                $header.InnerText = $title_header
                #check if img tag should be added
                if($img){
                    $img_tag = $card.CreateElement("img")
                    [void]$img_tag.SetAttribute('class','card-img')
                    [void]$img_tag.SetAttribute('src',$img)
                    [void]$img_tag.SetAttribute('alt','card_img')
                    #Force close tag <img/>
                    [void]$img_tag.AppendChild($card.CreateWhitespace(""))
                }
                elseif($i_class){
                    #Force close tag <i/>
                    $img_tag = $card.CreateElement("i")
                    [void]$img_tag.SetAttribute('class',$i_class)
                    [void]$img_tag.AppendChild($card.CreateWhitespace(""))
                }
                #create and append card title
                if($img_tag){
                    [void]$card_title.AppendChild($img_tag)
                }
                #Add header
                [void]$card_title.AppendChild($header)
                #Add to card header
                $card_header = $card.SelectSingleNode('//div[contains(@class,"card-header")]')
                [void]$card_header.AppendChild($card_title)
            }
            #Check if subtitle
            if($subtitle){
                $subtitle_element = $card.CreateElement("h6")
                [void]$subtitle_element.SetAttribute('class','card-subtitle text-muted')
                $subtitle_element.InnerText = $subtitle
                #Add to card header
                $card_header = $card.SelectSingleNode('//div[contains(@class,"card-title")]')
                [void]$card_header.AppendChild($subtitle_element)
            }
        }
    }
    Process{
        #Process body and footer elements
        if($PSBoundParameters.ContainsKey('body')){
            #Get body from main xml
            $card_body = $card.SelectSingleNode('//div[contains(@class,"card-body")]')
            if($body -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "card body")
                [void]$card_body.AppendChild($card.ImportNode($body.get_DocumentElement(), $True))
            }
            elseif($body -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "card body")
                [void]$card_body.AppendChild($card.ImportNode($body,$True))
            }
        }
        else{
            #Get body from main xml
            $card_body = $card.SelectSingleNode('//div[contains(@class,"card-body")]')
            Write-Verbose ($Script:messages.EmptyDiv -f "card body")
            #set blank
            [void]$card_body.AppendChild($card.CreateTextNode([string]::Empty))
        }
        #Check if also add element to footer element
        if($PSBoundParameters.ContainsKey('footer')){
            #Get footer from main xml
            $card_footer = $card.SelectSingleNode('//div[contains(@class,"card-footer")]')
            if($footer -is [System.Xml.XmlDocument]){
                Write-Verbose ($Script:messages.AppendDocElementTo -f "card footer")
                [void]$card_footer.AppendChild($card.ImportNode($footer.get_DocumentElement(), $True))
            }
            elseif($footer -is [System.Xml.XmlElement]){
                Write-Verbose ($Script:messages.AppendXmlElementTo -f "card footer")
                [void]$card_footer.AppendChild($card.ImportNode($footer,$True))
            }
        }
        else{#Blank footer
            #Get footer from main xml
            $card_footer = $card.SelectSingleNode('//div[contains(@class,"card-footer")]')
            if($null -ne $card_footer){
                Write-Verbose ($Script:messages.EmptyDiv -f "card footer")
                #set blank
                [void]$card_footer.AppendChild($card.CreateTextNode([string]::Empty))
            }
        }
    }
    End{
        return $card
    }
}
