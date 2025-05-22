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

Function New-HtmlExecutionInfoCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlExecutionInfoCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
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
        #Create a main div
        $DivElement = @{
            Name = 'div';
            ClassName = 'text-center';
            Template = $TemplateObject;
        }
        #Create element
        $mainDiv = New-HtmlTag @DivElement
    }
    Process{
        #create scan-details-container
        $DivElement = @{
            Name = 'div';
            ClassName = 'row scan-details-container';
            Template = $TemplateObject;
        }
        #Create element
        $divContainer = New-HtmlTag @DivElement
        #Add TenantId, domain, etc..
        Foreach($elem in $Script:RulesetInfo.GetEnumerator()){
            #Create label
            $DivElement = @{
                Name = 'div';
                ClassName = 'col-md-3 scan-label';
                Text = $elem.name;
                CreateTextNode = $true;
                Template = $TemplateObject;
            }
            #Create element
            $divLabel = New-HtmlTag @DivElement
            #Add to details container
            [void]$divContainer.AppendChild($divLabel);
            #Create info
            $DivElement = @{
                Name = 'div';
                ClassName = 'col-md-9 scan-info';
                Text = $elem.value;
                CreateTextNode = $true;
                Template = $TemplateObject;
            }
            #Create element
            $divValue = New-HtmlTag @DivElement
            #Add to details container
            [void]$divContainer.AppendChild($divValue);
        }
        #Add to main div
        [void]$mainDiv.AppendChild($divContainer);
        #Set card
        $p = @{
            CardTitle = "Ruleset details";
            CardCategory = "Execution info";
            ClassName = "h-100";
            Icon = "bi bi-list-check me-2";
            AppendObject = $mainDiv;
            Template = $TemplateObject;
        }
        New-HtmlContainerCard @p
    }
    End{
        #Nothing to do here
    }
}