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

Function New-HtmlScanDetailsCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlScanDetailsCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
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
            ClassName = 'row d-none container-fluid';
            Id = "execution-info";
            Template = $TemplateObject;
        }
        #Create element
        $divContent = New-HtmlTag @divProperties
    }
    Process{
        #Get new profile card
        $p = @{
            Template = $TemplateObject;
        }
        $profileCard = New-HtmlUserProfileCard @p
        If($profileCard){
            #Div properties
            $divProperties = @{
                Name = 'div';
                ClassName = 'col-md-6 grid-margin';
                AppendObject = $profileCard;
                Template = $TemplateObject;
            }
            #Create element
            $colMd6Div = New-HtmlTag @divProperties
            If($colMd6Div){
                [void]$divContent.AppendChild($colMd6Div);
            }
        }
        #Get Execution info card
        $p = @{
            Template = $TemplateObject;
        }
        $executionInfoCard = New-HtmlExecutionInfoCard @p
        If($executionInfoCard){
            #Div properties
            $divProperties = @{
                Name = 'div';
                ClassName = 'col-md-6 grid-margin';
                AppendObject = $executionInfoCard;
                Template = $TemplateObject;
            }
            #Create element
            $colMd6Div = New-HtmlTag @divProperties
            If($colMd6Div){
                [void]$divContent.AppendChild($colMd6Div);
            }
        }
        return $divContent
    }
}
