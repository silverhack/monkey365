﻿# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
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

Function New-HtmlAboutTool{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlAboutTool
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param()
    Begin{
        #Create social media data
        $social_media = @(
            [ordered]@{
                class = "social-icon text-xs-center"
                target = "_blank"
                href = "https://x.com/tr1ana"
                i_object = "bi bi-twitter-x"
            },
            [ordered]@{
                class = "social-icon text-xs-center"
                target = "_blank"
                href = "https://github.com/silverhack/monkey365"
                i_object = "bi bi-github"
            },
            [ordered]@{
                class = "social-icon text-xs-center"
                target = "_blank"
                href = "https://bsky.app/profile/tr1ana.bsky.social"
                i_object = "bi bi-square-fill"
            }
        )
        $paragraphs = @(
            'Monkey365 is an open-source security tool designed to allow detection of security flaws not only in Azure accounts, but also in Microsoft 365.',
            'It follows guidelines of the CIS Microsoft Azure Benchmark and CIS Microsoft 365 Benchmark.',
            'These modules are designed to return a series of potential security-related misconfigurations.',
            'For more information about Monkey365, please check out our <a class="modal-link" href="https://github.com/silverhack/monkey365" target="_blank">GitHub</a>.'
        )
        #Tool image
        #Create Monkey365 IMG
        If($Script:mode -eq 'cdn'){
            $baseUrl = ("{0}/{1}" -f $Script:Repository,'assets/inc-monkey/logo/MonkeyLogo.png');
            $img_src = Convert-UrlToJsDelivr -Url $baseUrl -Latest
        }
        Else{
            $img_src = ("{0}/{1}" -f $Script:LocalPath,'assets/inc-monkey/logo/MonkeyLogo.png');
        }
        #xml root
        [xml]$modal_body = '<div class="row"></div>'
        #Create div
        $content_div = $modal_body.CreateNode([System.Xml.XmlNodeType]::Element, $modal_body.Prefix, 'div', $modal_body.NamespaceURI);
        [void]$content_div.SetAttribute('class',"container-fluid")
        #Create IMG
        $img_attributes = @{
            src = $img_src;
            alt = 'monkey365';
            class = 'img-fluid';
        }
        $img_element = @{
            Name = 'img';
            Attributes = $img_attributes;
            Empty = $True;
            Template = $modal_body;
        }
        $img_object = New-HtmlTag @img_element
        #Create P tags
        foreach($paragraph in $paragraphs){
            $p_element = $modal_body.CreateNode([System.Xml.XmlNodeType]::Element, $modal_body.Prefix, 'p', $modal_body.NamespaceURI);
            #Set P InnerText
            $p_element.InnerText = $paragraph.ToString()
            #Add to div
            [void]$content_div.AppendChild($p_element);
        }
        #Add image and content to div
        [void]$modal_body.div.AppendChild($img_object)
        [void]$modal_body.div.AppendChild($content_div)
    }
    Process{
        #Create footer data
        $ul_object = $modal_body.CreateNode([System.Xml.XmlNodeType]::Element, $modal_body.Prefix, 'ul', $modal_body.NamespaceURI);
        #Set class to ul object
        [void]$ul_object.SetAttribute('class',"list-inline")
        foreach($social_element in $social_media){
            #Create li element
            $li_attr = @{
                class = 'list-inline-item';
            }
            $li_element = @{
                Name = 'li';
                Attributes = $li_attr;
                Empty = $True;
                Template = $modal_body;
            }
            $li_object = New-HtmlTag @li_element
            #Create i object
            $i_attr = @{
                class = $social_element.i_object;
            }
            $i_element = @{
                Name = 'i';
                Attributes = $i_attr;
                Empty = $True;
                Template = $modal_body;
            }
            $i_object = New-HtmlTag @i_element
            #Create a href element
            $a_attr = [ordered]@{
            }
            foreach($attr in $social_element.GetEnumerator()){
                if($attr.key -eq "class"){continue}
                [void]$a_attr.Add($attr.key,$attr.Value)
            }
            $a_element = @{
                Name = 'a';
                Attributes = $a_attr;
                Empty = $True;
                Template = $modal_body;
            }
            $a_object = New-HtmlTag @a_element
            #Set objects
            #Add i object to a href
            [void]$a_object.AppendChild($i_object)
            #Add a href to li
            [void]$li_object.AppendChild($a_object)
            #Add li to ul object
            [void]$ul_object.AppendChild($li_object)
        }
        #Create modal
        $p = @{
            Title = "About Monkey365";
            Id = "aboutMonkeyModal";
            FooterObject = $ul_object;
            FooterClass = "justify-content-center";
            BodyObject = $modal_body;
            IconHeaderClass = "bi bi-shield-shaded";
        }
        New-HtmlModal @p
    }
    End{
        #Nothing to do here
    }
}
