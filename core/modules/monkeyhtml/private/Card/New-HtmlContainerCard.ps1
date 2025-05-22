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

Function New-HtmlContainerCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlContainerCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $true, HelpMessage= "Card title")]
        [String]$CardTitle,

        [parameter(Mandatory= $false, HelpMessage= "Card category")]
        [String]$CardCategory,

        [parameter(Mandatory= $false, HelpMessage= "Card subtitle")]
        [String]$CardSubTitle,

        [parameter(Mandatory= $false, HelpMessage= "ID card")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "Style card")]
        [String]$Style,

        [parameter(Mandatory= $false, HelpMessage= "Class name")]
        [String[]]$ClassName,

        [parameter(Mandatory= $false, HelpMessage= "Img card")]
        [String]$Img,

        [parameter(Mandatory= $false, HelpMessage= "Icon card")]
        [String[]]$Icon,

        [parameter(Mandatory= $false, HelpMessage= "Card text")]
        [String]$CardContainerText,

        [parameter(Mandatory= $false, HelpMessage= "Append Object")]
        [Object]$AppendObject,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Set null
        $_img = $null
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
    }
    Process{
        Try{
            #New card
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-HtmlCard")
            $newCardPsboundParams = [ordered]@{}
            If($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                ForEach($p in $param.GetEnumerator()){
                    If($p.ToLower() -eq 'classname'){continue}
                    If($PSBoundParameters.ContainsKey($p)){
                        $newCardPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
                #Add null body object
                $newCardPsboundParams.Add('BodyObject',$null)
            }
            #Get card
            #Add monkey-card class name
            If($PSBoundParameters.ContainsKey('ClassName') -and $PSBoundParameters['ClassName']){
                $_Class = [String]::Join(' ',$ClassName);
                $newClass = ("monkey-card {0}" -f $_Class);
                $newCardPsboundParams.Add('ClassName',$newClass);
            }
            Else{
                $newCardPsboundParams.Add('ClassName','monkey-card')
            }
            $card = New-HtmlCard @newCardPsboundParams
            #Create monkey-header div class
            $DivElement = @{
                Name = 'div';
                ClassName = 'monkey-header';
                Template = $card.OwnerDocument;
            }
            #Create div element
            $monkeyHeader = New-HtmlTag @DivElement
            #Create card-title div class
            $DivElement = @{
                Name = 'div';
                ClassName = 'card-title';
                Template = $card.OwnerDocument;
            }
            #Create div element
            $cardTitleDiv = New-HtmlTag @DivElement
            #Add card category if present
            If($PSBoundParameters.ContainsKey('CardCategory') -and $PSBoundParameters['CardCategory']){
                #Create h6 card category
                $H6Element = @{
                    Name = 'h6';
                    ClassName = 'card-category';
                    Text = $PSBoundParameters['CardCategory'];
                    CreateTextNode = $true;
                    Template = $card.OwnerDocument;
                }
                #Create div element
                $category = New-HtmlTag @H6Element
                [void]$monkeyHeader.AppendChild($category);
            }
            #Get icon,svg or image
            If($PSBoundParameters.ContainsKey('Icon') -and $PSBoundParameters['Icon']){
                $iconClass = [String]::Join(' ',$PSBoundParameters['Icon']);
                #TODO
                $IElement = @{
                    Name = 'i';
                    ClassName = $iconClass;
                    Template = $card.OwnerDocument;
                }
                #Create div element
                $_img = New-HtmlTag @IElement
                #[void]$monkeyHeader.AppendChild($_img);
                [void]$cardTitleDiv.AppendChild($_img);
            }
            ElseIf($PSBoundParameters.ContainsKey('Img') -and $PSBoundParameters['Img']){
                $img_attributes = @{
                    src = $PSBoundParameters['Img'];
                    alt = $PSBoundParameters['CardTitle'];
                }
                $img_element = @{
                    Name = 'img';
                    Attributes = $img_attributes;
                    Template = $card.OwnerDocument;
                }
                $_img = New-HtmlTag @img_element
                #Import node
                #[void]$monkeyHeader.AppendChild($_img);
                [void]$cardTitleDiv.AppendChild($_img);
            }
            Else{
                $_img = $PSBoundParameters['CardTitle'] | Get-SvgIcon
                $img_attributes = @{
                    src = $_img;
                    alt = $PSBoundParameters['CardTitle'];
                }
                $img_element = @{
                    Name = 'img';
                    Attributes = $img_attributes;
                    Template = $card.OwnerDocument;
                }
                $_img = New-HtmlTag @img_element
                #Import node
                #[void]$monkeyHeader.AppendChild($_img);
                [void]$cardTitleDiv.AppendChild($_img);
            }
            #Create resource name h4
            $H4Element = @{
                Name = 'h4';
                ClassName = 'title-header';
                Text = $PSBoundParameters['CardTitle'];
                CreateTextNode = $true;
                Template = $card.OwnerDocument;
            }
            #Create div element
            $resourceName = New-HtmlTag @H4Element
            #Add to header
            #[void]$monkeyHeader.AppendChild($resourceName);
            [void]$cardTitleDiv.AppendChild($resourceName);
            #Append to monkey-header
            [void]$monkeyHeader.AppendChild($cardTitleDiv);
            #Append to card
            [void]$card.PrependChild($monkeyHeader);
            #Append object
            If($PSBoundParameters.ContainsKey('AppendObject') -and $PSBoundParameters['AppendObject']){
                #Get Card body
                $cardBody = $card.SelectSingleNode('//div[contains(@class,"card-body")]')
                $arrayObjects = [System.Collections.Generic.List[System.Object]]::new()
                If ($PSBoundParameters['AppendObject'] -is [System.Collections.IEnumerable] -and $PSBoundParameters['AppendObject'] -isnot [string]){
                    Foreach($obj in $PSBoundParameters['AppendObject']){
                        [void]$arrayObjects.Add($obj);
                    }
                }
                Else{
                    $arrayObjects.Add($PSBoundParameters['AppendObject'])
                }
                #Add objects
                ForEach($elem in $arrayObjects){
                    If($elem -is [System.Xml.XmlDocument]){
                        Write-Verbose ($script:messages.AppendDocElementTo -f "Body")
                        [void]$cardBody.AppendChild($card.OwnerDocument.ImportNode($elem.get_DocumentElement(), $True))
                    }
                    ElseIf($elem -is [System.Xml.XmlElement]){
                        Write-Verbose ($script:messages.AppendXmlElementTo -f "Body")
                        [void]$cardBody.AppendChild($card.OwnerDocument.ImportNode($elem,$true))
                    }
                    Else{
                        #Create text node
                        [void]$cardBody.AppendChild($card.OwnerDocument.CreateTextNode($elem.ToString()))
                    }
                }
            }
            return $card
        }
        Catch{
            Write-Warning "Unable to get container card"
            Write-Error $_
        }
    }
}