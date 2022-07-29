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

Function New-MonkeyEmptyCard{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyEmptyCard
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param()
    Begin{
        $main_col = $null
        #xml root
        $xml_root = [xml]'<div class="row d-none" id="MonkeyGlobalRow"></div>'
        #Get new card
        $params = @{
            defaultCard = $True;
            card_class = 'monkey-card';
            title_header = 'Monkey365 findings';
            img = (Get-HtmlIcon -icon_name "Monkey365");
            card_body_id = 'MonkeyIssues';
        }
        $global_card =  Get-HtmlCard @params
        if($global_card){
            #Add global card to new div
            $params = @{
                tagname = "div";
                classname = "col-md-12";
                appendObject = $global_card;
                own_template = $xml_root;
            }
            $main_col = New-HtmlTag @params
        }
    }
    Process{
        if($null -ne $main_col){
            #Add to main div
            [void]$xml_root.div.AppendChild($main_col)
        }
    }
    End{
        return $xml_root
    }
}
