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

Function New-HtmlTag{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlTag
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $true, HelpMessage= "Name")]
        [String]$Name,

        [parameter(Mandatory= $false, HelpMessage= "Tag class")]
        [String[]]$ClassName,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template,

        [parameter(Mandatory= $false, HelpMessage= "ID")]
        [String]$Id,

        [parameter(Mandatory= $false, HelpMessage= "Text")]
        [String]$Text,

        [parameter(Mandatory= $false, HelpMessage= "Attributes")]
        [Hashtable]$Attributes,

        [parameter(Mandatory= $false, HelpMessage= "Append Object")]
        [Object]$AppendObject,

        [parameter(Mandatory= $false, HelpMessage= "InnerText option")]
        [Switch]$InnerText,

        [parameter(Mandatory= $false, HelpMessage= "Create text node option")]
        [Switch]$CreateTextNode,

        [parameter(Mandatory= $false, HelpMessage= "Empty")]
        [Switch]$Empty,

        [parameter(Mandatory= $false, HelpMessage= "Use Short tag, i.e. (<a/>)")]
        [Switch]$ShortTag
    )
    Begin{
        #set Null
        $tag = $null;
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
        #create tag
        Try{
            $tag = $TemplateObject.CreateNode(
                [System.Xml.XmlNodeType]::Element,
                $TemplateObject.Prefix,
                $PSBoundParameters['Name'].ToString(),
                $TemplateObject.NamespaceURI
            );
            #set Attributes
            If($PSBoundParameters.ContainsKey('Attributes') -and $PSBoundParameters['Attributes']){
                ForEach($attr in $PSBoundParameters['Attributes'].GetEnumerator()){
                    [void]$tag.SetAttribute($attr.Name,$attr.Value)
                }
            }
            #Add class to tag
            If($PSBoundParameters.ContainsKey('ClassName') -and $PSBoundParameters['ClassName']){
                $_Class = [String]::Join(' ',$ClassName);
                $Tagclass = ("{0}" -f $_Class)
                [void]$tag.SetAttribute('class',$Tagclass)
            }
            #Set Id
            If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
                [void]$tag.SetAttribute('id',$Id)
            }
            #Add Text
            If($PSBoundParameters.ContainsKey('Text') -and $PSBoundParameters['Text']){
                #Set innertext
                If($PSBoundParameters.ContainsKey('InnerText') -and $PSBoundParameters['InnerText'].IsPresent){
                    $tag.InnerText = $PSBoundParameters['Text'].ToString()
                }
                ElseIf($PSBoundParameters.ContainsKey('CreateTextNode') -and $PSBoundParameters['CreateTextNode'].IsPresent){
                    [void]$tag.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['Text'].ToString()))
                }
                Else{
                    #Default CreateTextNode
                    [void]$tag.AppendChild($TemplateObject.CreateTextNode($PSBoundParameters['Text'].ToString()))
                }
            }
            #Append object
            If($PSBoundParameters.ContainsKey('AppendObject') -and $PSBoundParameters['AppendObject']){
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
                        Write-Verbose ($script:messages.AppendDocElementTo -f $PSBoundParameters['Name'])
                        [void]$tag.AppendChild($TemplateObject.ImportNode($elem.get_DocumentElement(), $True))
                    }
                    ElseIf($elem -is [System.Xml.XmlElement]){
                        Write-Verbose ($script:messages.AppendXmlElementTo -f $PSBoundParameters['Name'])
                        [void]$tag.AppendChild($TemplateObject.ImportNode($elem,$true))
                    }
                    Else{
                        #Create text node
                        [void]$tag.AppendChild($TemplateObject.CreateTextNode($elem.ToString()))
                    }
                }
            }
            #Check if empty
            If($PSBoundParameters.ContainsKey('Empty') -and $PSBoundParameters['Empty'].IsPresent){
                $tag.InnerText = [string]::Empty
                $tag.isEmpty = $True
            }
            #Check if short tag format
            If($PSBoundParameters.ContainsKey('ShortTag') -and $PSBoundParameters['ShortTag'].IsPresent){
                $tag.isEmpty = $True
            }
        }
        Catch{
            Write-Warning ($script:messages.TagErrorMessage -f $PSBoundParameters['Name'].ToString())
            Write-Debug $_.Exception
        }
    }
    End{
        #Close if no childnodes
        If($tag.HasChildNodes -eq $false){
            $tag.InnerText = [string]::Empty
        }
        #return tag
        return $tag
    }
}
