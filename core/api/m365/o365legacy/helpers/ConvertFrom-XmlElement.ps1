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

function ConvertFrom-XmlElement{
    <#
    .Synopsis
        Converts named nodes of an element to properties of a PSObject, recursively.
    .Parameter Element
        The element to convert to a PSObject.
    .Parameter SelectXmlInfo
        Output from the Select-Xml cmdlet.
    .Inputs
        Microsoft.PowerShell.Commands.SelectXmlInfo output from Select-Xml.
    .Outputs
        System.Management.Automation.PSCustomObject object created from selected XML.
    .Link
        Select-Xml
    .Example
        Select-Xml /configuration/appSettings/add web.config |ConvertFrom-XmlElement.ps1
        key              value
        ---              -----
        webPages:Enabled false
    #>
    Param(
    [Parameter(ParameterSetName='Element',Position=0,Mandatory=$true,ValueFromPipeline=$true)][Xml.XmlElement] $Element
    )
    Process{
        if(($Element.SelectNodes('*') |Group-Object Name |Measure-Object).Count -eq 1){
            @($Element.SelectNodes('*') |ConvertFrom-XmlElement)
        }
        else{
            $properties = @{}
            #$Element.Attributes |% {[void]$properties.Add($_.Name.split(':')[1],$_.Value)}
            foreach($node in $Element.ChildNodes | Where-Object {$_.Name -and $_.Name -ne '#whitespace'}){
                $subelements = $node.SelectNodes('*') |Group-Object Name
                $value =
                    if($node.InnerText -and !$subelements)
                    {
                        $node.InnerText
                    }
                    elseif(($subelements |Measure-Object).Count -eq 1)
                    {
                        @($node.SelectNodes('*') |ConvertFrom-XmlElement)
                    }
                    else
                    {
                        ConvertFrom-XmlElement $node
                    }
                if(!$properties.Contains($node.Name)){ # new property
                    $property = $node.Name.split(':')[1]
                    if($property){
                        [void]$properties.Add($node.Name.split(':')[1],$value)
                    }
                }
                else{ # property name collision!
                    if($properties[$node.Name] -isnot [Collections.Generic.List[object]]){
                        $property = $node.Name.split(':')[1]
                        if($property){
                            $properties[$property] = ([Collections.Generic.List[object]]@($properties[$property],$value))
                        }
                    }
                    else{
                        $property = $node.Name.split(':')[1]
                        if($property){
                            $properties[$property].Add($value)
                        }
                    }
                }
            }
            New-Object PSObject -Property $properties
        }
    }
}
