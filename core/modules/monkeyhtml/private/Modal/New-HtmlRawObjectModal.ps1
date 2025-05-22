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
        [parameter(Mandatory= $True, HelpMessage= "Data")]
        [Object]$Data,

        [parameter(Mandatory= $false, HelpMessage= "Object Type")]
        [String]$Format = 'json',

        [parameter(Mandatory= $false, HelpMessage= "Modal Id")]
        [string]$Id,

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
    }
    Process{
        #Set ID modal
        If($PSBoundParameters.ContainsKey('Id') -and $PSBoundParameters['Id']){
            $myId = $PSBoundParameters['Id']
        }
        Else{
            #Set random number
            $myId = ("MonkeyRawDataModal{0}" -f (Get-Random -Maximum 1500 -Minimum 1))
        }
        #Set data
        $ModalBody = [xml] '<pre id="rawObject"></pre>'
        $CodeId = ("MonkeyRawDataObject_{0}" -f (Get-Random -Minimum 20 -Maximum 1000))
        #Create code tag
        $CodeTag = $ModalBody.CreateNode([System.Xml.XmlNodeType]::Element, $ModalBody.Prefix, 'code', $ModalBody.NamespaceURI);
        #Set attributes
        $codeClass = ("monkey-raw-data {0}" -f $Format);
        [void]$CodeTag.SetAttribute('class',$codeClass);
        [void]$CodeTag.SetAttribute('id',$CodeId);
        #Format data
        If($Format.ToLower() -eq 'json'){
            $rawData = $Data | ConvertTo-Json -Depth 100 -Compress
        }
        Else{
            $rawData = $Data
        }
        [void]$CodeTag.AppendChild($ModalBody.CreateTextNode($rawData));
        #Append to pre
        [void]$ModalBody.pre.AppendChild($CodeTag);
        #Create modal
        $p = @{
            Title = "Raw Data";
            Id= $myId;
            Size = "large";
            AddCloseButton = $True;
            BodyObject = $ModalBody;
            IconHeaderClass = "bi bi-code-square";
            Template = $TemplateObject;
        }
        New-HtmlModal @p
    }
    End{
        #Nothing to do here
    }
}
