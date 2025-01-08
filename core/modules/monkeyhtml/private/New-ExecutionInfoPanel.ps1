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

Function New-ExecutionInfoPanel{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExecutionInfoPanel
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param()
    Begin{
        $main_dashboard_template = [xml] '<div class="container-fluid d-none" id="execution-info"></div>'
        $root_div = $main_dashboard_template.SelectSingleNode("div")
        $div = $main_dashboard_template.CreateElement("div")
        [void]$div.SetAttribute('class','row')
        #Get User Profile card
        $user_profile = New-UserProfile
        if($user_profile -is [System.Xml.XmlDocument]){
            $user_profile = $main_dashboard_template.ImportNode($user_profile.get_DocumentElement(), $True)
        }
        #Get Exec info card
        $exec_info_card = New-ExecutionInfoCard
        if($exec_info_card -is [System.Xml.XmlDocument]){
            $exec_info_card = $main_dashboard_template.ImportNode($exec_info_card.get_DocumentElement(), $True)
        }
    }
    Process{
        #Add col-md5 with main charts
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-6 grid-margin')
        [void]$div_col.AppendChild($user_profile);
        [void]$div.AppendChild($div_col);
        [void]$root_div.AppendChild($div)
        #Add col-md7 with main charts
        $div_col = $main_dashboard_template.CreateElement("div")
        [void]$div_col.SetAttribute('class','col-md-6 grid-margin')
        [void]$div_col.AppendChild($exec_info_card);
        [void]$div.AppendChild($div_col);
        [void]$root_div.AppendChild($div)
    }
    End{
        #return profile
        return $main_dashboard_template
    }
}

