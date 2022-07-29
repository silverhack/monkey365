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

Function New-HtmlRawObjectModal{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlRawObjectModal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [Object]$raw_data,

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [String]$format = 'json',

            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [string]$id
    )
    Begin{
        $modal_body = [xml] '<pre id="rawObject"></pre>'
        $code_id = ("monkey_object_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
        #Create code tag
        $code_tag = $modal_body.CreateNode([System.Xml.XmlNodeType]::Element, $modal_body.Prefix, 'code', $modal_body.NamespaceURI);
        #Set attributes
        [void]$code_tag.SetAttribute('class',$format);
        [void]$code_tag.SetAttribute('id',$code_id);
        $raw_data = $raw_data | ConvertTo-Json -Depth 10 -Compress
        [void]$code_tag.AppendChild($modal_body.CreateTextNode($raw_data));
        #Append to pre
        [void]$modal_body.pre.AppendChild($code_tag);

    }
    Process{
        #Create modal
        $param = @{
            modal_title = "Raw Data";
            id_modal= $id;
            modal_size = "large";
            WithFooter = $True;
            addCloseButton = $True;
            Body = $modal_body;
            modal_icon_header_class = "bi bi-code-square fa-lg me-2";
        }
        $modal_raw_data = New-HtmlModal @param
    }
    End{
        return $modal_raw_data
    }
}
