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

Function New-HtmlErrorModal{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlErrorModal
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "ID Modal")]
        [String]$Id,

        [parameter(Mandatory= $true, HelpMessage= "Modal title")]
        [String]$Title,

        [parameter(Mandatory= $false, HelpMessage= "Modal size")]
        [ValidateSet("small","large","extra")]
        [String]$Size,

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
        #Get command metadata
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-HtmlModal")
        $newPsboundParams = [ordered]@{}
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        #Add icon
        [void]$newPsboundParams.Add('IconHeaderClass',"bi bi-cloud-drizzle")
        New-HtmlModal @newPsboundParams
    }
    End{
        #Nothing to do here
    }
}
