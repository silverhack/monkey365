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
        [parameter(Mandatory=$false,ValueFromPipeline = $True, HelpMessage="Hashtable")]
        [HashTable]$InputObject,

        [parameter(Mandatory=$false,HelpMessage="Object Name")]
        [String]$psName
    )
    Begin{
        $object = $null
    }
    Process{
        If(([System.Collections.IDictionary]).IsAssignableFrom($InputObject.GetType())){
            #$_.GetEnumerator() | ForEach-Object { Add-Member -inputObject $object -memberType NoteProperty -name $_.Name -value $_.Value }
            foreach ( $key in $InputObject.Keys | Where-Object {$null -ne $InputObject[$_] -and $InputObject[$_].GetType() -eq @{}.GetType() } ) {
                $InputObject[$key] = Convert-HashTableToPsObject $InputObject[$key]
            }
            #Create custom object
            $object = New-Object PSObject -Property $InputObject
        }
    }
    End{
        if($null -ne $object -and $psName){
            $object.PSObject.TypeNames.Insert(0,$psName)
        }
        $object
    }
}

