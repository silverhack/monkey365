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

function xmlNodeToPsCustomObject ($node){
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: xmlNodeToPsCustomObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

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
    return $hash | ConvertTo-PsCustomObjectFromHashtable
}

function ConvertTo-PsCustomObjectFromHashtable {
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )] [object[]]$hashtable
    );

    begin { $i = 0; }

    process {
        foreach ($myHashtable in $hashtable) {
            if ($myHashtable.GetType().Name -eq 'hashtable') {
                $output = New-Object -TypeName PsObject;
                Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value {
                    Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1];
                };
                $myHashtable.Keys | Sort-Object | ForEach-Object {
                    $output.AddNote($_, $myHashtable.$_);
                }
                $output
            } else {
                Write-Warning "Index $i is not of type [hashtable]";
            }
            $i += 1;
        }
    }
}
