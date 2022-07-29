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

function Convert-XmlToPsObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-XmlToPsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, HelpMessage="XML Node")]
        [Object]$node
    )
    $hash = @{}
    foreach($attribute in $node.attributes){
        $hash.$($attribute.name) = $attribute.Value
    }
    $childNodesList = ($node.childnodes | Where-Object {$_ -ne $null}).LocalName
    foreach($childnode in ($node.childnodes | Where-Object {$_ -ne $null})){
        if(($childNodesList | Where-Object {$_ -eq $childnode.LocalName}).count -gt 1){
            if(!($hash.$($childnode.LocalName))){
                $hash.$($childnode.LocalName) += @()
            }
            if ($null -ne $childnode.'#text') {
                $hash.$($childnode.LocalName) += $childnode.'#text'
            }
            $hash.$($childnode.LocalName) += xmlNodeToPsCustomObject($childnode)
        }else{
            if ($null -ne $childnode.'#text') {
                $hash.$($childnode.LocalName) = $childnode.'#text'
            }else{
                $hash.$($childnode.LocalName) = xmlNodeToPsCustomObject($childnode)
            }
        }
    }
    return $hash
}
