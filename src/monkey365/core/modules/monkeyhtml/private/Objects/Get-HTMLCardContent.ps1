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

Function Get-HTMLCardContent{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HTMLCardContent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $True, HelpMessage= "Paragraph name")]
        [String]$Name,

        [parameter(Mandatory= $false, HelpMessage= "String data to convert to HTML")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Content,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
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
        #Div properties
        $divProperties = @{
            Name = 'div';
            ClassName = 'card-content';
            Template = $TemplateObject;
        }
        #Create element
        $divContent = New-HtmlTag @divProperties
        #Create card H element
        $HProperties = @{
            Name = 'h6';
            ClassName = 'card-title','font-weight-bold';
            Template = $TemplateObject;
        }
        #Create element
        $H6 = New-HtmlTag @HProperties
        #Create card p element
        $PProperties = @{
            Name = 'p';
            ClassName = 'card-text';
            Template = $TemplateObject;
        }
        #Create element
        $PText = New-HtmlTag @PProperties
    }
    Process{
        #Get Description
        $HtmlContent = $divContent.Clone()
        #Clone card-title
        $_H6 = $H6.Clone();
        #Set description
        $_H6.InnerText = $PSBoundParameters['Name'];
        #Clone text obj
        $textObj = $PText.Clone()
        #Get Data
        If($null -ne $PSBoundParameters['Content'] -and $PSBoundParameters['Content']){
            $outHtml = $PSBoundParameters['Content'] | Convert-MarkDownToHtml -UseAdvancedExtensions -RemoveBlankAndTabs -RemoveImplicitParagraph
            #Add to text
            [void]$textObj.AppendChild($TemplateObject.CreateTextNode($outHtml.ToString()))
        }
        #Add to card content
        [void]$HtmlContent.AppendChild($_H6);
        [void]$HtmlContent.AppendChild($textObj);
    }
    End{
        return $HtmlContent
    }
}
