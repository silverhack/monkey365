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

Function Get-HtmlContainerCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlContainerCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Xml.XmlElement]])]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Matched items')]
        [Object]$InputObject,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Set array
        $allObjects = [System.Collections.Generic.List[System.Xml.XmlElement]]::new()
        #Set template
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
        #Get items
        $Resources = $InputObject | Group-Object -Property serviceType -ErrorAction Ignore
        Foreach($Resource in $Resources){
            If (-NOT [String]::IsNullOrEmpty($Resource.Name)){
                #Set array
                $bodyObjects = [System.Collections.Generic.List[System.Xml.XmlElement]]::new()
                Write-Verbose ($Script:messages.AppendElementMessageInfo -f "a new HTML row", $Resource.Name )
                #Create a new row object
                $DivElement = @{
                    Name = 'div';
                    ClassName = 'row d-none';
                    Id = $Resource.Name.ToLower().Replace(' ','-');
                    Template = $TemplateObject;
                }
                #Create element
                $row = New-HtmlTag @DivElement
                #Create a new col
                $DivElement = @{
                    Name = 'div';
                    ClassName = 'col-md-12';
                    Template = $TemplateObject;
                }
                #Create element
                $col = New-HtmlTag @DivElement
                #Get search filter
                $searchFilter = New-HtmlCardFilter -Template $TemplateObject
                [void]$bodyObjects.Add($searchFilter);
                #Get all findings
                #Div properties
                $divProperties = @{
                    Name = 'div';
                    ClassName = 'monkey-card-data';
                    Id = ("{0}-findings" -f $Resource.Name.ToLower().Replace(' ',''))
                    Template = $TemplateObject;
                }
                #Create element
                $divContent = New-HtmlTag @divProperties
                #Get findings
                $allFindings = $Resource.Group | New-FindingCard -Template $TemplateObject
                #Append all findings
                Foreach($finding in @($allFindings)){
                    [void]$divContent.AppendChild($finding);
                }
                #Add to array
                [void]$bodyObjects.Add($divContent);
                #Get Img
                $svg = $Resource.Name | Get-SvgIcon
                #Create a new container card
                $p = @{
                    CardTitle = $Resource.Name;
                    Img = $svg;
                    AppendObject = $bodyObjects;
                }
                $containerCard = New-HtmlContainerCard @p
                If($containerCard){
                    #Change title-header
                    $h = $containerCard.SelectSingleNode('//h4[@class="title-header"]')
                    [void]$h.SetAttribute('class',"resource-name")
                    #Add container card to col
                    [void]$col.AppendChild($containerCard);
                    #Add col to main row
                    [void]$row.AppendChild($col);
                    #Close div tags
                    $divs = $row.SelectNodes("//div")
                    $divs | ForEach-Object {
                        If($_.IsEmpty){
                            [void]$_.AppendChild($TemplateObject.CreateWhitespace(""))
                        }
                    }
                    #Add to array
                    [void]$allObjects.Add($row);
                }
                <#
                #Set h4 element
                $HElement = @{
                    Name = 'h4';
                    ClassName = 'resource-name';
                    Text = $Resource.Name;
                    InnerText = $true;
                    Template = $row;
                }
                #Create element
                $H4Tag = New-HtmlTag @HElement
                #Get SVG icon
                $svg = $Resource.Name | Get-SvgIcon -LocalPath C:\monkey365_dev\newhtml
                $img_attributes = @{
                    src = $svg;
                    alt = $Resource.Name;
                }
                $img_element = @{
                    Name = 'img';
                    Attributes = $img_attributes;
                    Empty = $true;
                    Template = $row;
                }
                $img = New-HtmlTag @img_element
                #Get header
                $header = $row.SelectSingleNode('//div[@class="monkey-header"]')
                If($null -ne $header){
                    #Add header and h4
                    [void]$header.AppendChild($img);
                    [void]$header.AppendChild($H4Tag);
                }
                #Get Card body
                $body = $row.SelectSingleNode('//div[@class="card-body"]')
                #Get search filter
                $searchFilter = New-HtmlCardFilter -Template $row
                #append child
                [void]$body.AppendChild($searchFilter);
                #Create div object
                #Div properties
                $divProperties = @{
                    Name = 'div';
                    ClassName = 'monkey-card-data';
                    Id = ("{0}-findings" -f $Resource.Name.ToLower().Replace(' ',''))
                    Template = $row;
                }
                #Create element
                $divContent = New-HtmlTag @divProperties
                #Get findings
                $allFindings = $Resource.Group | New-FindingCard -Template $row
                #Append all findings
                Foreach($finding in @($allFindings)){
                    [void]$divContent.AppendChild($finding);
                }
                #append child
                [void]$body.AppendChild($divContent);
                #Import node
                $row = $TemplateObject.ImportNode($row.DocumentElement,$true);
                #Close div tags
                $divs = $row.SelectNodes("//div")
                $divs | ForEach-Object {
                    If($_.IsEmpty){
                        [void]$_.AppendChild($TemplateObject.CreateWhitespace(""))
                    }
                }
                #>
                #Add to array
                [void]$allObjects.Add($row);
            }
        }
        return $allObjects
    }
    End{
    }
}