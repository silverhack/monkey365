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

Function Get-HTMLCardCompliance{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HTMLCardCompliance
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $True, HelpMessage= "Paragraph name")]
        [String]$Name,

        [parameter(Mandatory= $True, HelpMessage= "Compliance objects")]
        [Object]$Content,

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
        #Create BR separator
        $br = $TemplateObject.CreateNode(
            [System.Xml.XmlNodeType]::Element,
            $TemplateObject.Prefix,
            "br",
            $TemplateObject.NamespaceURI
        );
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
            Foreach($complianceObj in @($PSBoundParameters['Content']).Where({$null -ne $_})){
                #check if PsObject
                $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($complianceObj.GetType())
                #check if PsObject
                $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($complianceObj.GetType())
                If($isPsObject -or $isPsCustomObject){
                    #Get Name, version and reference
                    $Name = $complianceObj | Select-Object -ExpandProperty name -ErrorAction Ignore
                    $Version = $complianceObj | Select-Object -ExpandProperty version -ErrorAction Ignore
                    $Reference = $complianceObj | Select-Object -ExpandProperty reference -ErrorAction Ignore
                    If($null -ne $Name){
                        #Set span object
                        $spanProperties = @{
                            Name = 'span';
                            ClassName = 'badge bg-primary badge-xl';
                            Text = $Name;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create element
                        $spanObject = New-HtmlTag @spanProperties
                        #Add to textObj
                        [void]$textObj.AppendChild($spanObject);
                    }
                    If($null -ne $Version){
                        #Set span object
                        $spanProperties = @{
                            Name = 'span';
                            ClassName = 'badge bg-info badge-xl';
                            Text = $Version;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create element
                        $spanObject = New-HtmlTag @spanProperties
                        #Add to textObj
                        [void]$textObj.AppendChild($spanObject);
                    }
                    If($null -ne $Reference){
                        #Set span object
                        $spanProperties = @{
                            Name = 'span';
                            ClassName = 'badge bg-success badge-xl';
                            Text = $Reference;
                            CreateTextNode = $True;
                            Template = $TemplateObject;
                        }
                        #Create element
                        $spanObject = New-HtmlTag @spanProperties
                        #Add to textObj
                        [void]$textObj.AppendChild($spanObject);
                    }
                    #Add BR element
                    [void]$textObj.AppendChild($br.Clone())
                }
                ElseIf ($complianceObj -is [string] -and $complianceObj.Length -gt 0){
                    #Set span object
                    $spanProperties = @{
                        Name = 'span';
                        ClassName = 'badge bg-primary badge-xl';
                        Text = $complianceObj;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                    #Create element
                    $spanObject = New-HtmlTag @spanProperties
                    #Add to textObj
                    [void]$textObj.AppendChild($spanObject);
                    #Add BR element
                    [void]$textObj.AppendChild($br.Clone())
                }
            }
        }
        #Add to card content
        [void]$HtmlContent.AppendChild($_H6);
        [void]$HtmlContent.AppendChild($textObj);
    }
    End{
        return $HtmlContent
    }
}
