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

Function Get-JSHelper{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-JSHelper
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Xml.XmlElement]])]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #main template
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Set array
        $allHelpers = [System.Collections.Generic.List[System.Xml.XmlElement]]::new()
        $helpers = $Script:Config.head | Select-Object -ExpandProperty helpers -ErrorAction Ignore
    }
    Process{
        Try{
            ForEach($newHelper in @($helpers).GetEnumerator()){
                $tagName = $newHelper | Select-Object -ExpandProperty tagName -ErrorAction Ignore
                $properties = $newHelper | Select-Object -ExpandProperty properties -ErrorAction Ignore
                $text = $newHelper | Select-Object -ExpandProperty text -ErrorAction Ignore
                If($null -ne $tagName){
                    Try{
                        $tag = $TemplateObject.CreateNode(
                            [System.Xml.XmlNodeType]::Element,
                            $TemplateObject.Prefix,
                            $tagName.ToString(),
                            $TemplateObject.NamespaceURI
                        );
                        If($null -ne $properties){
                            ForEach($prop in $properties.Psobject.Properties){
                                If($prop.Name -eq 'crossorigin' -and ($Script:mode -ne 'cdn' -or $Script:mode -ne 'localcdn')){
                                    continue
                                }
                                If($prop.Name -eq 'integrity' -and ($Script:mode -ne 'cdn' -or $Script:mode -ne 'localcdn')){
                                    continue
                                }
                                If($Script:mode -eq 'cdn' -and $prop.Name -in @("src","href")){
                                    #Get baseUrl
                                    If($null -ne (Get-Variable -Name Repository -Scope Script -ErrorAction Ignore)){
                                        $_url = ("{0}/{1}" -f $Script:Repository,$prop.Value);
                                        $jsDelivr = Convert-UrlToJsDelivr -Url $_url -Latest
                                        [void]$tag.SetAttribute($prop.Name,$jsDelivr)
                                    }
                                    Else{
                                        Write-Warning $Script:messages.BaseUrlErrorMessage
                                    }
                                }
                                ElseIf($Script:mode -eq 'localcdn' -and $prop.Name -in @("src","href")){
                                    #Get baseUrl
                                    If($null -ne (Get-Variable -Name Repository -Scope Script -ErrorAction Ignore)){
                                        $_url = ("{0}/{1}" -f $Script:Repository,$prop.Value);
                                        [void]$tag.SetAttribute($prop.Name,$_url);
                                    }
                                    Else{
                                        Write-Warning $Script:messages.BaseUrlErrorMessage
                                    }
                                }
                                Else{
                                    If($prop.Name -in @("src","href")){
                                        $_url = ("{0}/{1}" -f $Script:LocalPath,$prop.Value);
                                        [void]$tag.SetAttribute($prop.Name,$_url)
                                    }
                                    Else{
                                        [void]$tag.SetAttribute($prop.Name,$prop.value)
                                    }
                                }
                            }
                        }
                        If($null -ne $text){
                            $tag.InnerText = $text.ToString()
                        }
                        Else{
                            $tag.InnerText = [string]::Empty
                        }
                        [void]$allHelpers.Add($tag);
                    }
                    Catch{
                        Write-Error $_
                    }
                }
            }
            #return object
            $allHelpers
        }
        Catch{
            Write-Error $_
        }
    }
}