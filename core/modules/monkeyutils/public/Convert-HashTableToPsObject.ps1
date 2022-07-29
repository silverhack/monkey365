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

function Convert-HashTableToPsObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-HashTableToPsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [HashTable]$hashtable,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$psName
    )
    Begin{
        #$object = New-Object PSObject
    }
    Process{
        #$_.GetEnumerator() | ForEach-Object { Add-Member -inputObject $object -memberType NoteProperty -name $_.Name -value $_.Value }
        foreach ( $key in $hashtable.Keys | Where-Object {$null -ne $hashtable[$_] -and $hashtable[$_].GetType() -eq @{}.GetType() } ) {
            $hashtable[$key] = Convert-HashTableToPsObject $hashtable[$key]
        }
        #Create custom object
        $object = New-Object PSObject -Property $hashtable
    }
    End{
        if($psName){
            $object.PSObject.TypeNames.Insert(0,$psName)
        }
        $object
    }
}
