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

Function Get-AllModalHtmlObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AllModalHtmlObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Xml.XmlElement]])]
    Param (
        [parameter(Mandatory= $True, HelpMessage= "Report")]
        [Object]$Report,

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
        #set Array
        $modals = [System.Collections.Generic.List[System.Xml.XmlElement]]::new()
    }
    Process{
        #Get modal error
        $modalErrorObj = New-HtmlErrorModal -Title "Monkey365 error" -Id "monkey365error" -size "large"
        #Add to array
        [void]$modals.Add($modalErrorObj);
        $aboutAuthor = New-HtmlAboutAuthorModal
        #Import modal
        $aboutAuthor = $TemplateObject.ImportNode($aboutAuthor, $True)
        #Add to array
        [void]$modals.Add($aboutAuthor);
        $aboutTool = New-HtmlAboutTool
        #Import modal
        $aboutTool = $TemplateObject.ImportNode($aboutTool, $True)
        #Add to array
        [void]$modals.Add($aboutTool);
        #Add rest of modals
        Foreach($finding in @($Report).Where({$_.level.ToLower() -ne "good" -or $_.level.ToLower() -ne "manual"})){
            $extendedData = $finding.output.html.extendedData
            If($null -ne $extendedData){
                Foreach($rawObject in @($extendedData)){
                    If($null -ne $rawObject -and ([System.Collections.IDictionary]).IsAssignableFrom($rawObject.GetType())){
                        $id = $rawObject.Item('id')
                        $format = $rawObject.Item('format')
                        $rawData = $rawObject.Item('rawData')
                        If($null -ne $rawData -and $null -ne $format -and $null -ne $id){
                            $p = @{
                                Data = $rawData;
                                Format = $format;
                                Id = $id;
                            }
                            $modalObj = New-HtmlRawObjectModal @p
                            If($modalObj){
                                #Add to array
                                [void]$modals.Add($modalObj);
                            }
                        }
                    }
                }
            }
        }
        #return object
        return $modals
    }
    End{
        #Nothing to do here
    }
}
