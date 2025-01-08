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
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$tagname = "mytag",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [hashtable]$attributes,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$classname = [string]::Empty,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$id_value = [string]::Empty,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$innerText,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$createTextNode,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Xml.XmlDocument]$own_template,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$appendObject,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$empty
    )
    Begin{
        $tag = $null
        if($PSBoundParameters.ContainsKey('own_template')){
            $tmp_template = $own_template
        }
        else{
            $tmp_template = $script:template
        }
    }
    Process{
        #create tag
        try{
        $tag = $tmp_template.CreateNode(
                    [System.Xml.XmlNodeType]::Element,
                    $tmp_template.Prefix,
                    $tagname.ToString(),
                    $tmp_template.NamespaceURI
                );
        }
        catch{
            Write-Warning ($script:messages.unableToCreateTag -f $tagname.ToString())
            Write-Debug $_.Exception
        }
        #Add attributes if any
        if($null -ne $tag){
            try{
                #set Attributes
                if($PSBoundParameters.ContainsKey('attributes')){
                    foreach($attr in $attributes.GetEnumerator()){
                        [void]$tag.SetAttribute($attr.Name,$attr.Value)
                    }
                }
                #Set class
                if($PSBoundParameters.ContainsKey('classname')){
                    [void]$tag.SetAttribute('class',$classname)
                }
                #Set id
                if($PSBoundParameters.ContainsKey('id_value')){
                    [void]$tag.SetAttribute('id',$id_value)
                }
                #check if empty tag
                if($empty){
                    #$tag.InnerText = [string]::Empty
                    $tag.isEmpty = $True
                }
                elseif($PSBoundParameters.ContainsKey('innerText')){
                    $tag.InnerText = $innerText.ToString()
                }
                elseif($PSBoundParameters.ContainsKey('createTextNode')){
                    [void]$tag.AppendChild($tmp_template.CreateTextNode($createTextNode.ToString()))
                }
                elseif($PSBoundParameters.ContainsKey('appendObject')){
                    $arrayObjects = New-Object System.Collections.Generic.List[System.Object]
                    if($appendObject -ne [System.Array]){
                        $arrayObjects.Add($appendObject)
                    }
                    else{
                        $arrayObjects = $appendObject
                    }
                    foreach($elem in $appendObject){
                        if($elem -is [System.Xml.XmlDocument]){
                            Write-Verbose ($script:messages.AppendDocElementTo -f $tagname)
                            [void]$tag.AppendChild($tmp_template.ImportNode($elem.get_DocumentElement(), $True))
                        }
                        elseif($elem -is [System.Xml.XmlElement]){
                            Write-Verbose ($script:messages.AppendXmlElementTo -f $tagname)
                            [void]$tag.AppendChild($elem)
                        }
                    }
                }
            }
            catch{
                Write-Verbose $_
            }
        }
        else{
            Write-Warning ($script:messages.unableToCreateTag -f $tagname.ToString())
        }
    }
    End{
        #return tag
        return $tag
    }
}

